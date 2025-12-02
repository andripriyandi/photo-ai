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

// Node 18+ / 20 punya global fetch, tidak perlu node-fetch
export const generateImages = functions.https.onCall(
    async (data: GenerateImagesRequest, context): Promise<GenerateImagesResponse> => {
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

        // 1. Download original image dari Storage
        const [bytes] = await file.download();
        const base64Image = bytes.toString("base64");

        const prompts =
            styles.length > 0
                ? styles
                : [
                    "Travel beach Instagram style photo",
                    "Night city break, neon lights, portrait style",
                    "Cozy cafe, laptop, lifestyle shot",
                ];

        // 2. Ambil GEMINI API KEY dari env/config
        const apiKey =
            process.env.GEMINI_API_KEY ||
            (functions.config().gemini && functions.config().gemini.key);

        if (!apiKey) {
            throw new functions.https.HttpsError(
                "failed-precondition",
                "Gemini API key is not configured.",
            );
        }

        const generatedPaths: string[] = [];

        // 3. Loop style → call Gemini → simpan ke Storage
        for (let i = 0; i < prompts.length; i++) {
            const prompt = prompts[i];

            const res = await fetch(
                `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=${apiKey}`,
                {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
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
                console.error("Gemini error", res.status, text);
                throw new functions.https.HttpsError(
                    "internal",
                    "Error calling Gemini API.",
                );
            }

            const json = (await res.json()) as any;
            const candidates = json.candidates ?? [];
            const parts = candidates[0]?.content?.parts ?? [];

            const imagePart = parts.find(
                (p: any) => p.inlineData && p.inlineData.data,
            );

            if (!imagePart) {
                console.error("No image returned from Gemini for prompt index", i);
                continue;
            }

            const imageDataBase64: string = imagePart.inlineData.data;
            const buffer = Buffer.from(imageDataBase64, "base64");

            const outputPath = `users/${uid}/sessions/${sessionId}/generated-${i}.png`;
            const outFile = bucket.file(outputPath);

            await outFile.save(buffer, {
                contentType: "image/png",
            });

            generatedPaths.push(outputPath);
        }

        return {
            originalImagePath,
            generatedImagePaths: generatedPaths,
        };
    },
);
