# Online wildlife identification setup

The camera sends photos to `identify_animal.php` only when the local scan has no confident match. The PHP endpoint calls Gemini and keeps the Gemini API key on the server. Unknown species are returned as suggestions and are not inserted into the animal catalog automatically.

1. Create a Gemini API key at [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Set the Windows system environment variable `GEMINI_API_KEY` to that key.
3. Restart Apache in XAMPP so PHP receives the new variable.
4. Check `http://localhost/BruneiGoOnlineApps/wildlife_api/identify_animal.php` returns `Only POST requests are allowed.`; the online scan requires a photo POST request.

Keep the key on the server. Do not put it in Flutter source or commit it to the repository. The captured photo is sent to Google's Gemini API for identification when the local profile scan does not match.
