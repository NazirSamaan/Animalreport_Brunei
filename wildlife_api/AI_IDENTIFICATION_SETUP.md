# Online wildlife identification setup

The camera sends photos to `identify_animal.php` only when the local scan has no confident match. The PHP endpoint calls Gemini and keeps the Gemini API key on the server. Unknown species are returned as suggestions and are not inserted into the animal catalog automatically.

1. Create a Gemini API key at [Google AI Studio](https://aistudio.google.com/app/apikey).
2. For the hosted app, edit the alwaysdata site `nazir21.alwaysdata.net` and add `GEMINI_API_KEY` to its environment variables. Save the site settings. Keep the existing database variables.
3. For local XAMPP only, set the Windows system environment variable `GEMINI_API_KEY` and restart Apache.
4. Test a photo POST to `https://nazir21.alwaysdata.net/wildlife_api/identify_animal.php` with multipart field `image`. A GET only checks routing and does not verify the key or model access.

The server tries `gemini-3.5-flash-lite` first and falls back to `gemini-3.6-flash` for model-not-found, quota, or temporary service errors. Free-tier access depends on Google's account eligibility and quotas; keep billing disabled if only free usage is wanted. Successful responses contain `status: identified`; unclear photos return `status: unidentified`.

Keep the key on the server. Do not put it in Flutter source or commit it to the repository. The captured photo is sent to Google's Gemini API for identification when the local profile scan does not match.
