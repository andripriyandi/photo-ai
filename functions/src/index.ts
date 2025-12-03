import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

interface GenerateImagesRequest {
    originalImagePath?: string;
    styles?: string[];
    sessionId?: string;
}

interface GenerateImagesResponse {
    originalImagePath: string;
    generatedImagePaths: string[];
}

export const generateImages = functions
    .region("asia-southeast2")
    .runWith({
        timeoutSeconds: 60,
        memory: "1GB",
    })
    .https.onCall(
        async (
            data: GenerateImagesRequest,
            context: functions.https.CallableContext,
        ): Promise<GenerateImagesResponse> => {
            const uid = context.auth?.uid;

            if (!uid) {
                throw new functions.https.HttpsError(
                    "unauthenticated",
                    "User must be authenticated.",
                );
            }

            const originalImagePath = data.originalImagePath;
            const styles = Array.isArray(data.styles) ? data.styles : [];
            const sessionId = data.sessionId ?? Date.now().toString();

            if (!originalImagePath) {
                throw new functions.https.HttpsError(
                    "invalid-argument",
                    "originalImagePath is required.",
                );
            }

            const bucket = admin.storage().bucket();
            const file = bucket.file(originalImagePath);

            // Download sekali, pakai berulang di semua request ke Gemini
            const [bytes] = await file.download();
            const base64Image = bytes.toString("base64");

            const prompts =
                styles.length > 0
                    ? styles
                    : [
                        "Travel beach Instagram style photo, bright daylight, blue ocean, warm skin tone",
                        "Night city break, neon lights, urban street portrait, moody lighting",
                        "Cozy cafe, laptop, warm indoor light, coffee on table, relaxed pose",
                    ];

            const apiKey =
                process.env.GEMINI_API_KEY ||
                (functions.config().gemini && functions.config().gemini.key);

            if (!apiKey) {
                throw new functions.https.HttpsError(
                    "failed-precondition",
                    "Gemini API key is not configured.",
                );
            }

            // array untuk menyimpan path hasil. Index = index prompt
            const generatedPaths: (string | undefined)[] = [];

            await Promise.all(
                prompts.map(async (prompt, i) => {
                    try {
                        const res = await fetch(
                            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent",
                            {
                                method: "POST",
                                headers: {
                                    "Content-Type": "application/json",
                                    "x-goog-api-key": apiKey,
                                },
                                body: JSON.stringify({
                                    contents: [
                                        {
                                            parts: [
                                                {
                                                    inlineData: {
                                                        mimeType: "image/jpeg",
                                                        data: base64Image,
                                                    },
                                                },
                                                { text: prompt },
                                            ],
                                        },
                                    ],
                                    generationConfig: {
                                        responseModalities: ["IMAGE"],
                                        imageConfig: {
                                            aspectRatio: "4:5",
                                        },
                                    },
                                }),
                            },
                        );

                        if (!res.ok) {
                            const text = await res.text();
                            console.error(
                                "Gemini error for prompt index",
                                i,
                                "status",
                                res.status,
                                text,
                            );
                            return;
                        }

                        const json = (await res.json()) as any;
                        const candidates = json.candidates ?? [];
                        const parts = candidates[0]?.content?.parts ?? [];

                        const imagePart = parts.find(
                            (p: any) => p.inlineData && p.inlineData.data,
                        );

                        if (!imagePart) {
                            console.error(
                                "No image returned from Gemini for prompt index",
                                i,
                            );
                            return;
                        }

                        const imageDataBase64: string = imagePart.inlineData.data;
                        const buffer = Buffer.from(imageDataBase64, "base64");

                        const outputPath = `users/${uid}/sessions/${sessionId}/generated-${i}.png`;
                        const outFile = bucket.file(outputPath);

                        await outFile.save(buffer, { contentType: "image/png" });

                        generatedPaths[i] = outputPath;
                    } catch (err) {
                        console.error("Error processing prompt index", i, err);
                    }
                }),
            );

            const finalPaths = generatedPaths.filter(
                (p): p is string => typeof p === "string",
            );

            if (finalPaths.length === 0) {
                throw new functions.https.HttpsError(
                    "internal",
                    "No images were generated.",
                );
            }

            return {
                originalImagePath,
                generatedImagePaths: finalPaths,
            };
        },
    );
