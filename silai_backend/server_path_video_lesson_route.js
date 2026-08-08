/**
 * 🎓 PATCHED — /api/generate-video-lesson route
 * --------------------------------------------------------------------------
 * Replaces the route handler with advanced keyword filtering and clean 
 * primitive JSON deep cloning to resolve empty scene object casts in Flutter.
 * --------------------------------------------------------------------------
 */

const axios = require('axios');
const DraftingEngine = require('./server_patch_drafting_engine.js'); // adjust path as needed

const videoLessonJobs = {};

app.post('/api/generate-video-lesson', async (req, res) => {
  const { garmentType, measurements, fabricType, languageCode, categoryKey } = req.body;

  if (!garmentType && !categoryKey) {
    return res.status(400).json({ success: false, error: 'garmentType or categoryKey is required.' });
  }

  const sarvamLangMap = { ta: 'ta-IN', en: 'en-IN', hi: 'hi-IN', te: 'te-IN', kn: 'kn-IN' };
  const targetLang = sarvamLangMap[languageCode] || 'ta-IN';

  // Recompute segments for THIS garment + THESE measurements so the names
  // we hand to Groq match exactly what Flutter will render.
  const safeCategory = ['trousers', 'skirt', 'shirt', 'dress', 'blouse'].includes(categoryKey)
    ? categoryKey
    : (categoryKey || garmentType || 'dress').toLowerCase();

  const CANVAS_SCALE = 12;
  const wasteAdjustment = 0.5; // matches your fallback cotton profile
  let resultPattern;
  try {
    resultPattern = DraftingEngine[safeCategory](measurements || {}, wasteAdjustment, CANVAS_SCALE);
  } catch (e) {
    resultPattern = DraftingEngine['dress'](measurements || {}, wasteAdjustment, CANVAS_SCALE);
  }
  const availableSegments = Object.keys(resultPattern.segments || {});

  const videoId = `lesson_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  videoLessonJobs[videoId] = { status: 'processing' };

  res.json({ success: true, videoId });

  try {
    const langName = languageCode === 'ta' ? 'Tamil' : languageCode === 'hi' ? 'Hindi' : languageCode === 'te' ? 'Telugu' : languageCode === 'kn' ? 'Kannada' : 'English';

    const scriptPrompt = `You are a friendly tailoring teacher speaking directly to a student in ${langName}.

Garment: ${safeCategory}
Fabric: ${fabricType || 'cotton'}
Measurements: ${JSON.stringify(measurements || {})}

Available pattern regions for this garment (use these EXACT names, nothing else):
${availableSegments.join(', ')}

Write 4 to 6 short teaching steps (1-2 sentences each) that walk through marking, cutting, pinning, and stitching THIS garment, in a sensible order using the regions listed above.

Return ONLY valid JSON, no markdown:
{
  "steps": [
    {
      "title": "short title",
      "narration": "1-2 sentence spoken instruction in ${langName}",
      "segment": "one of: ${availableSegments.join(' | ')}",
      "action": "cut | pin | stitch"
    }
  ]
}

Rules:
- "segment" MUST be one of the exact names listed above — do not invent new names.
- "action" controls which tool animates: "cut" shows scissors, "pin" shows a pin, "stitch" shows a needle+thread.
- Order steps in a realistic tailoring sequence (usually: mark/cut outline first, then curves, then seams, then hem, then stitching).`;

    const scriptResponse = await groq.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      response_format: { type: 'json_object' },
      messages: [{ role: 'user', content: scriptPrompt }],
      temperature: 0.4,
    });

    const scriptData = JSON.parse(scriptResponse.choices[0].message.content.trim());
    let steps = scriptData.steps || [];

    // --- 🛠️ STEP 1: SMART SERVER-SIDE RE-MAPPING FOR AI TEXT GENERATIONS ---
   // --- 🛠️ STEP 1: UNIVERSAL SERVER-SIDE RE-MAPPING (DRESS & BLOUSE) ---
    steps = steps.map((s) => {
      let cleanSeg = (s.segment || '').toLowerCase().trim();
      
      // 1. கழுத்து மற்றும் தோள் பகுதி (Neck & Shoulder)
      if (cleanSeg.includes('neck') || cleanSeg.includes('shoulder') || cleanSeg.includes('கழுத்து') || cleanSeg.includes('தோள்')) {
        cleanSeg = availableSegments.includes('neckline') ? 'neckline' : (availableSegments.includes('back_neck') ? 'back_neck' : cleanSeg);
      } 
      // 2. கைகுழி மற்றும் கை நீளம் (Armhole & Sleeve)
      else if (cleanSeg.includes('armhole') || cleanSeg.includes('sleeve') || cleanSeg.includes('கைகுழி') || cleanSeg.includes('கை')) {
        cleanSeg = availableSegments.includes('armhole_curve') ? 'armhole_curve' : (availableSegments.includes('sleeve_curve') ? 'sleeve_curve' : cleanSeg);
      } 
      // 3. பட்டி, பட்டை மற்றும் இடுப்பு பகுதி (Darts, Waist & Blouse Patti / Pattai)
      else if (cleanSeg.includes('waist') || cleanSeg.includes('bodice') || cleanSeg.includes('side') || cleanSeg.includes('பொருத்தம்') || cleanSeg.includes('பட்டை') || cleanSeg.includes('அளவுகளை')) {
        cleanSeg = availableSegments.includes('front_waist_dart') ? 'front_waist_dart' : 
                   (availableSegments.includes('waistline_join') ? 'waistline_join' : 
                   (availableSegments.includes('underbust_line') ? 'underbust_line' : 
                   (availableSegments.includes('side_seam') ? 'side_seam' : cleanSeg)));
      } 
      // 4. கீழ் விளிம்பு (Hemline)
      else if (cleanSeg.includes('hem') || cleanSeg.includes('skirt') || cleanSeg.includes('bottom') || cleanSeg.includes('கீழ்') || cleanSeg.includes('விளிம்பு')) {
        cleanSeg = availableSegments.includes('hemline') ? 'hemline' : (availableSegments.includes('skirt_hem_curve') ? 'skirt_hem_curve' : cleanSeg);
      }

      return {
        ...s,
        // பாதுகாப்பு வளையம்: ஒருவேளை மேட்ச் ஆகவில்லை என்றால் முதல் செக்மென்ட்டை எடுத்துக்கொள்ளும்
        segment: availableSegments.includes(cleanSeg) ? cleanSeg : (availableSegments[0] || 'neckline'),
        action: ['cut', 'pin', 'stitch'].includes(s.action) ? s.action : 'cut',
      };
    });

    const fullNarrationText = steps.map((s, i) => `${i + 1}. ${s.narration}`).join(' ... ');

    let audioBase64 = null;
    try {
      const ttsResponse = await axios.post(
        'https://api.sarvam.ai/text-to-speech',
        {
          text: fullNarrationText.slice(0, 2400),
          target_language_code: targetLang,
          model: 'bulbul:v3',
          speaker: 'priya',
          pace: 0.95,
        },
        {
          headers: { 'api-subscription-key': process.env.SARVAM_API_KEY, 'Content-Type': 'application/json' },
          timeout: 25000,
        }
      );
      audioBase64 = ttsResponse.data.audios?.[0] || null;
    } catch (ttsErr) {
      console.error('⚠️ Sarvam TTS failed:', ttsErr.response?.data || ttsErr.message);
    }

    const CHARS_PER_SEC = 14;
    let cursor = 0;
    const timedSteps = steps.map((s) => {
      const dur = Math.max(2.5, s.narration.length / CHARS_PER_SEC);
      const stepData = { ...s, startSec: cursor, durationSec: dur };
      cursor += dur + 0.6;
      return stepData;
    });

    // --- 🛠️ STEP 2: DEEP SANITIZATION & EXPLICIT CANVAS BOUNDARIES ---
    const serializedSegments = JSON.parse(JSON.stringify(resultPattern.segments || {}));

    videoLessonJobs[videoId] = {
      status: 'completed',
      steps: timedSteps,
      audioBase64,
      totalDurationSec: cursor,
      garmentType: safeCategory,
      languageCode,
      segments: serializedSegments, // Cleaned primitive dictionary data block
      canvasOffset: { x: 15, y: 45 },
      canvasSize: { 
        width: resultPattern.width || 300, 
        height: resultPattern.height || 300 
      }
    };
  } catch (err) {
    console.error('⚠️ Video lesson generation failed:', err.message);
    videoLessonJobs[videoId] = {
      status: 'failed',
      error: { code: 'GENERATION_FAILED', message: err.message },
    };
  }
});

app.get('/api/video-lesson-status/:videoId', (req, res) => {
  const job = videoLessonJobs[req.params.videoId];
  if (!job) {
    return res.status(404).json({ status: 'failed', error: { code: 'NOT_FOUND', message: 'Job not found' } });
  }
  return res.json({ videoId: req.params.videoId, ...job });
});