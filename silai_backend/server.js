require('dotenv').config();
const express = require('express');
const fs = require('fs');
const path = require('path');
const Groq = require('groq-sdk');
const axios = require('axios');
const { Client } = require('@gradio/client'); // npm install @gradio/client

const app = express();

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const KNOWLEDGE_BASE_PATH = path.join(__dirname, 'tailoring_knowledge.json');
let tailoringKnowledge = [];
try {
  tailoringKnowledge = JSON.parse(fs.readFileSync(KNOWLEDGE_BASE_PATH, 'utf8'));
  console.log("📚 RAG Engine: Tailoring knowledge base indexed successfully!");
} catch (e) {
  console.log("⚠️ RAG Engine Warning: Using fallback runtime memory profiles.");
  tailoringKnowledge = [
    { "fabricType": "cotton", "wasteAdjustmentInches": 0.5, "instructions": "பருத்தித் துணி துவைத்த பின் சுருங்கும் தன்மை கொண்டது." },
    { "fabricType": "silk", "wasteAdjustmentInches": 0.2, "instructions": "பட்டுத் துணி வழுக்கும் தன்மை கொண்டது." }
  ];
}

/**
 * 📐 ADVANCED UNIVERSAL PRODUCTION DRAFTING ENGINE
 * --------------------------------------------------------------------------
 * Every garment function returns a `segments` object — named key-point
 * arrays in the SAME coordinate space as svgContent. Flutter uses these to
 * animate scissors/needle along the real cutting/stitching lines.
 * --------------------------------------------------------------------------
 */
const DraftingEngine = {
  blouse: (m, waste, scale) => {
    const chestVal = parseFloat(m.chest || 36);
    const lengthVal = parseFloat(m.length || 14);
    const neckDepth = parseFloat(m.frontNeckDepth || 6);

    const mainWidth = ((chestVal / 4) + 1.5 + waste) * scale;
    const totalHeight = lengthVal * scale;
    const shoulderWidth = mainWidth * 0.45;
    const armholeDepth = (chestVal * 0.2) * scale;
    const allowance = 0.5 * scale;
    const dartLocationX = mainWidth * 0.5;

    let cmTicks = "";
    for (let x = 50; x <= 50 + mainWidth; x += (scale * 0.3937)) {
      cmTicks += `<line x1="${x}" y1="${20 + totalHeight}" x2="${x}" y2="${20 + totalHeight + 5}" style="stroke:#7f8c8d; stroke-width:0.8;" />`;
    }

    const svgContent = `
      <path d="M 50,20 L ${50 + shoulderWidth},15 C ${50 + shoulderWidth + 15},${15 + armholeDepth * 0.5} ${50 + mainWidth + allowance - 5},${20 + armholeDepth * 0.8} ${50 + mainWidth + allowance},${20 + armholeDepth} L ${50 + mainWidth + allowance - 15},${20 + totalHeight + allowance} L ${50 - allowance},${20 + totalHeight + allowance} C ${50 - allowance},${20 + totalHeight * 0.5} 50,${20 + neckDepth * scale + allowance} 50,20 Z" style="stroke:#1a73e8; stroke-width:3; fill:#fdfdfd;" />
      <path d="M 50,20 L ${50 + shoulderWidth},20 C ${50 + shoulderWidth},${20 + armholeDepth * 0.5} ${50 + mainWidth - 5},${20 + armholeDepth * 0.8} ${50 + mainWidth},${20 + armholeDepth} L ${50 + mainWidth - 12},${20 + totalHeight} L 50,${20 + totalHeight} C 50,${20 + totalHeight * 0.5} 50,${20 + neckDepth * scale} 50,20 Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
      <path d="M ${50 + dartLocationX - 10},${20 + totalHeight} L ${50 + dartLocationX},${20 + totalHeight * 0.55} L ${50 + dartLocationX + 10},${20 + totalHeight}" style="stroke:#e67e22; stroke-width:2; fill:none;" />
      ${cmTicks}
      <text x="60" y="${20 + armholeDepth + 20}" font-family="sans-serif" font-size="11px" fill="#1a73e8" font-weight="bold">✂️ CUT ALONG ARMHOLE CURVE</text>
    `;

    const segments = {
      neckline: [
        { x: 50, y: 20 },
        { x: 50, y: 20 + neckDepth * scale * 0.5 },
        { x: 50, y: 20 + neckDepth * scale },
      ],
      shoulder: [
        { x: 50, y: 20 },
        { x: 50 + shoulderWidth, y: 15 },
      ],
      armhole_curve: [
        { x: 50 + shoulderWidth, y: 15 },
        { x: 50 + mainWidth + allowance - 5, y: 20 + armholeDepth * 0.8 },
        { x: 50 + mainWidth + allowance, y: 20 + armholeDepth },
      ],
      side_seam: [
        { x: 50 + mainWidth + allowance, y: 20 + armholeDepth },
        { x: 50 + mainWidth + allowance - 15, y: 20 + totalHeight + allowance },
      ],
      hemline: [
        { x: 50 + mainWidth + allowance - 15, y: 20 + totalHeight + allowance },
        { x: 50 + dartLocationX, y: 20 + totalHeight + allowance },
        { x: 50 - allowance, y: 20 + totalHeight + allowance },
      ],
      dart: [
        { x: 50 + dartLocationX - 10, y: 20 + totalHeight },
        { x: 50 + dartLocationX, y: 20 + totalHeight * 0.55 },
        { x: 50 + dartLocationX + 10, y: 20 + totalHeight },
      ],
    };

    return { svgContent, yardage: "1.00 Yards", width: mainWidth + 120, height: totalHeight + 100, segments };
  },

  shirt: (m, waste, scale) => {
    const chestVal = parseFloat(m.chest || 38);
    const lengthVal = parseFloat(m.length || 28);
    const sleeveVal = parseFloat(m.sleeveLength || 24);

    const bodyWidth = ((chestVal / 4) + 2 + waste) * scale;
    const bodyHeight = lengthVal * scale;
    const sleeveWidth = ((chestVal / 4) + 0.5) * scale;
    const sleeveHeight = sleeveVal * scale;

    const shoulderSlope = 1.5 * scale;
    const armholeCurveDepth = (chestVal * 0.22) * scale;
    const neckScoopX = (chestVal * 0.08) * scale;
    const neckScoopY = (chestVal * 0.09) * scale;
    const allowance = 0.5 * scale;

    let cmTicks = "";
    for (let y = 20; y <= 20 + bodyHeight; y += (scale * 0.3937)) {
      cmTicks += `<line x1="35" y1="${y}" x2="41" y2="${y}" style="stroke:#7f8c8d; stroke-width:0.8;" />`;
    }

    const svgContent = `
      <path d="M ${40 + neckScoopX},20 L ${40 + bodyWidth * 0.85},${20 + shoulderSlope} C ${40 + bodyWidth * 0.75},${20 + armholeCurveDepth * 0.5} ${40 + bodyWidth + allowance},${20 + armholeCurveDepth * 0.8} ${40 + bodyWidth + allowance},${20 + armholeCurveDepth} L ${40 + bodyWidth + allowance},${20 + bodyHeight + allowance} L ${40 - allowance},${20 + bodyHeight + allowance} L ${40 - allowance},${20 + neckScoopY} Q 40,20 ${40 + neckScoopX},20 Z" style="stroke:#1a73e8; stroke-width:3; fill:#f9fbfd;" />
      <path d="M ${40 + neckScoopX},20 L ${40 + bodyWidth * 0.85},${20 + shoulderSlope} C ${40 + bodyWidth * 0.75},${20 + armholeCurveDepth * 0.5} ${40 + bodyWidth},${20 + armholeCurveDepth * 0.8} ${40 + bodyWidth},${20 + armholeCurveDepth} L ${40 + bodyWidth},${20 + bodyHeight} L 40,${20 + bodyHeight} L 40,${20 + neckScoopY} Q 40,20 ${40 + neckScoopX},20 Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
      <path d="M ${80 + bodyWidth},20 L ${80 + bodyWidth + sleeveWidth},20 L ${80 + bodyWidth + sleeveWidth},${20 + sleeveHeight} L ${80 + bodyWidth + 30},${20 + sleeveHeight} C ${80 + bodyWidth + 20},${20 + armholeCurveDepth} ${80 + bodyWidth},${20 + armholeCurveDepth * 0.5} ${80 + bodyWidth},20 Z" style="stroke:#1a73e8; stroke-width:3; fill:#f9fbfd;" />
      ${cmTicks}
      <text x="50" y="${20 + armholeCurveDepth + 30}" font-family="sans-serif" font-size="11px" fill="#1a73e8" font-weight="bold">✂️ FOLLOW BLUE ARMHOLE CURVE</text>
    `;

    const segments = {
      neckline: [
        { x: 40 - allowance, y: 20 + neckScoopY },
        { x: 40, y: 20 },
        { x: 40 + neckScoopX, y: 20 },
      ],
      shoulder: [
        { x: 40 + neckScoopX, y: 20 },
        { x: 40 + bodyWidth * 0.85, y: 20 + shoulderSlope },
      ],
      armhole_curve: [
        { x: 40 + bodyWidth * 0.85, y: 20 + shoulderSlope },
        { x: 40 + bodyWidth + allowance, y: 20 + armholeCurveDepth * 0.8 },
        { x: 40 + bodyWidth + allowance, y: 20 + armholeCurveDepth },
      ],
      side_seam: [
        { x: 40 + bodyWidth + allowance, y: 20 + armholeCurveDepth },
        { x: 40 + bodyWidth + allowance, y: 20 + bodyHeight + allowance },
      ],
      hemline: [
        { x: 40 + bodyWidth + allowance, y: 20 + bodyHeight + allowance },
        { x: 40 - allowance, y: 20 + bodyHeight + allowance },
      ],
      sleeve_seam: [
        { x: 80 + bodyWidth, y: 20 },
        { x: 80 + bodyWidth + sleeveWidth, y: 20 },
        { x: 80 + bodyWidth + sleeveWidth, y: 20 + sleeveHeight },
        { x: 80 + bodyWidth + 30, y: 20 + sleeveHeight },
      ],
    };

    return { svgContent, yardage: ((lengthVal + sleeveVal + 6) / 36).toFixed(2) + " Yards", width: (bodyWidth * 2.5) + 150, height: Math.max(bodyHeight, sleeveHeight) + 100, segments };
  },

  trousers: (m, waste, scale) => {
    const waistVal = parseFloat(m.waist || 32);
    const lengthVal = parseFloat(m.length || 40);

    const waistWidth = ((waistVal / 4) + 1 + waste) * scale;
    const hipWidth = waistWidth + (2 * scale);
    const crotchDepth = (waistVal / 4 + 2.5) * scale;
    const kneeWidth = waistWidth * 0.75;
    const bottomAnkleWidth = waistWidth * 0.55;
    const allowance = 0.5 * scale;

    let cmTicks = "";
    for (let y = 20; y <= 20 + (lengthVal * scale); y += (scale * 0.3937)) {
      cmTicks += `<line x1="34" y1="${y}" x2="40" y2="${y}" style="stroke:#7f8c8d; stroke-width:0.8;" />`;
    }

    const svgContent = `
      <path d="M 40,20 L ${40 + waistWidth},20 L ${40 + hipWidth},${20 + crotchDepth * 0.4} C ${40 + hipWidth},${20 + crotchDepth * 0.7} ${40 + waistWidth + 30},${20 + crotchDepth} ${40 + waistWidth + 45 + allowance},${20 + crotchDepth} L ${40 + kneeWidth + allowance},${20 + (lengthVal * 0.55) * scale} L ${40 + bottomAnkleWidth + allowance},${20 + lengthVal * scale + allowance} L ${40 - allowance},${20 + lengthVal * scale + allowance} Z" style="stroke:#1a73e8; stroke-width:3; fill:#fdfdfd;" />
      <path d="M 40,20 L ${40 + waistWidth},20 L ${40 + hipWidth - allowance},${20 + crotchDepth * 0.4} C ${40 + hipWidth - allowance},${20 + crotchDepth * 0.7} ${40 + waistWidth + 30},${20 + crotchDepth} ${40 + waistWidth + 45},${20 + crotchDepth} L ${40 + kneeWidth},${20 + (lengthVal * 0.55) * scale} L ${40 + bottomAnkleWidth},${20 + lengthVal * scale} L 40,${20 + lengthVal * scale} Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
      <line x1="${40 + waistWidth * 0.5}" y1="50" x2="${40 + waistWidth * 0.5}" y2="${20 + lengthVal * scale - 30}" style="stroke:#5f6368; stroke-width:1.5; stroke-dasharray:8,4;" />
      ${cmTicks}
      <text x="${40 + waistWidth * 0.5 + 8}" y="80" font-family="sans-serif" font-size="10px" fill="#5f6368" font-weight="bold">GRAIN LINE / நேர் இழை</text>
      <text x="50" y="${20 + crotchDepth - 10}" font-family="sans-serif" font-size="11px" fill="#d93025" font-weight="bold">🧵 CROTCH SEAM AREA / கிாட்ச் பகுதி</text>
    `;

    const segments = {
      waistline: [
        { x: 40, y: 20 },
        { x: 40 + waistWidth, y: 20 },
      ],
      hip_curve: [
        { x: 40 + waistWidth, y: 20 },
        { x: 40 + hipWidth, y: 20 + crotchDepth * 0.4 },
      ],
      crotch_seam: [
        { x: 40 + hipWidth, y: 20 + crotchDepth * 0.4 },
        { x: 40 + waistWidth + 30, y: 20 + crotchDepth },
        { x: 40 + waistWidth + 45 + allowance, y: 20 + crotchDepth },
      ],
      inner_leg_seam: [
        { x: 40 + waistWidth + 45 + allowance, y: 20 + crotchDepth },
        { x: 40 + kneeWidth + allowance, y: 20 + (lengthVal * 0.55) * scale },
        { x: 40 + bottomAnkleWidth + allowance, y: 20 + lengthVal * scale + allowance },
      ],
      hemline: [
        { x: 40 + bottomAnkleWidth + allowance, y: 20 + lengthVal * scale + allowance },
        { x: 40 - allowance, y: 20 + lengthVal * scale + allowance },
      ],
      grain_line: [
        { x: 40 + waistWidth * 0.5, y: 50 },
        { x: 40 + waistWidth * 0.5, y: 20 + lengthVal * scale - 30 },
      ],
    };

    return { svgContent, yardage: ((lengthVal * 2 + 8) / 36).toFixed(2) + " Yards", width: hipWidth * 2.2 + 100, height: lengthVal * scale + 100, segments };
  },

  skirt: (m, waste, scale) => {
    const waistVal = parseFloat(m.waist || 28);
    const lengthVal = parseFloat(m.length || 32);

    const waistQuarter = ((waistVal / 4) + 1 + waste) * scale;
    const baseSweepWidth = waistQuarter * 2.6;
    const allowance = 0.5 * scale;

    let cmTicks = "";
    for (let x = 40; x <= 40 + baseSweepWidth; x += (scale * 0.3937)) {
      cmTicks += `<line x1="${x}" y1="${30 + lengthVal * scale}" x2="${x}" y2="${30 + lengthVal * scale + 5}" style="stroke:#7f8c8d; stroke-width:0.8;" />`;
    }

    const svgContent = `
      <path d="M 80,30 Q ${80 + waistQuarter * 0.5},${30 + 15} ${80 + waistQuarter + allowance},30 L ${40 + baseSweepWidth + allowance},${30 + lengthVal * scale + allowance} Q ${40 + baseSweepWidth * 0.5},${30 + lengthVal * scale + 20} ${40 - allowance},${30 + lengthVal * scale + allowance} Z" style="stroke:#1a73e8; stroke-width:3; fill:#fdfdfd;" />
      <path d="M 80,30 Q ${80 + waistQuarter * 0.5},${30 + 10} ${80 + waistQuarter},30 L ${40 + baseSweepWidth},${30 + lengthVal * scale} Q ${40 + baseSweepWidth * 0.5},${30 + lengthVal * scale + 10} 40,${30 + lengthVal * scale} Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
      <text x="50" y="${30 + lengthVal * 0.4}" font-family="sans-serif" font-size="10px" fill="#e67e22" font-weight="bold" transform="rotate(-90 50 ${30 + lengthVal * 0.4})">▼ PLACE ON FOLD / மடிப்பு பகுதி</text>
      ${cmTicks}
      <text x="95" y="70" font-family="sans-serif" font-size="11px" fill="#1a73e8" font-weight="bold">✂️ CUT CURVED HEMLINE UNIFORMLY</text>
    `;

    const segments = {
      waistline: [
        { x: 80, y: 30 },
        { x: 80 + waistQuarter * 0.5, y: 30 + 15 },
        { x: 80 + waistQuarter + allowance, y: 30 },
      ],
      side_seam: [
        { x: 80 + waistQuarter + allowance, y: 30 },
        { x: 40 + baseSweepWidth + allowance, y: 30 + lengthVal * scale + allowance },
      ],
      hemline_curve: [
        { x: 40 + baseSweepWidth + allowance, y: 30 + lengthVal * scale + allowance },
        { x: 40 + baseSweepWidth * 0.5, y: 30 + lengthVal * scale + 20 },
        { x: 40 - allowance, y: 30 + lengthVal * scale + allowance },
      ],
      fold_line: [
        { x: 50, y: 30 },
        { x: 50, y: 30 + lengthVal * scale },
      ],
    };

    return { svgContent, yardage: ((lengthVal * 2 + 4) / 36).toFixed(2) + " Yards", width: baseSweepWidth + 160, height: lengthVal * scale + 120, segments };
  },

  dress: (m, waste, scale) => {
    const chestVal = parseFloat(m.chest || 36);
    const lengthVal = parseFloat(m.length || 42);

    const frontWidth = ((chestVal / 4) + 1.5 + waste) * scale;
    const naturalBodiceHeight = lengthVal * 0.35 * scale;
    const flareSkirtWidth = frontWidth * 2.5;
    const armholeDepth = (chestVal * 0.2) * scale;
    const shoulderWidth = frontWidth * 0.5;
    const allowance = 0.5 * scale;

    let cmTicks = "";
    for (let y = 20; y <= 20 + (lengthVal * scale); y += (scale * 0.3937)) {
      cmTicks += `<line x1="54" y1="${y}" x2="60" y2="${y}" style="stroke:#7f8c8d; stroke-width:0.8;" />`;
    }

    const svgContent = `
      <path d="M 60,20 L ${60 + shoulderWidth},15 C ${60 + shoulderWidth + 15},${15 + armholeDepth * 0.5} ${60 + frontWidth + allowance},${20 + armholeDepth * 0.8} ${60 + frontWidth + allowance},${20 + armholeDepth} L ${60 + frontWidth + allowance - 10},${20 + naturalBodiceHeight} L ${60 + flareSkirtWidth + allowance},${20 + lengthVal * scale + allowance} Q ${60 + flareSkirtWidth * 0.5},${20 + lengthVal * scale + 25} ${20 - allowance},${20 + lengthVal * scale + allowance} L ${60 - allowance},${20 + naturalBodiceHeight} Z" style="stroke:#1a73e8; stroke-width:3; fill:#fdfdfd;" />
      <path d="M 60,20 L ${60 + shoulderWidth},20 C ${60 + shoulderWidth},${20 + armholeDepth * 0.5} ${60 + frontWidth},${20 + armholeDepth * 0.8} ${60 + frontWidth},${20 + armholeDepth} L ${60 + frontWidth - 8},${20 + naturalBodiceHeight} L ${60 + flareSkirtWidth},${20 + lengthVal * scale} Q ${60 + flareSkirtWidth * 0.5},${20 + lengthVal * scale + 15} 20,${20 + lengthVal * scale} L 60,${20 + naturalBodiceHeight} Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
      ${cmTicks}
      <text x="${60 + frontWidth + 20}" y="${20 + naturalBodiceHeight}" font-family="sans-serif" font-size="11px" fill="#e67e22" font-weight="bold">👗 WAISTLINE JOIN / இடுப்பு பகுதி இணைப்பு</text>
    `;

    const segments = {
      neckline: [
        { x: 60, y: 20 },
        { x: 60 + shoulderWidth, y: 15 },
      ],
      armhole_curve: [
        { x: 60 + shoulderWidth, y: 15 },
        { x: 60 + frontWidth + allowance, y: 20 + armholeDepth * 0.8 },
        { x: 60 + frontWidth + allowance, y: 20 + armholeDepth },
      ],
      bodice_seam: [
        { x: 60 + frontWidth + allowance, y: 20 + armholeDepth },
        { x: 60 + frontWidth + allowance - 10, y: 20 + naturalBodiceHeight },
      ],
      waistline_join: [
        { x: 60 + frontWidth + allowance - 10, y: 20 + naturalBodiceHeight },
        { x: 60 - allowance, y: 20 + naturalBodiceHeight },
      ],
      skirt_hem_curve: [
        { x: 60 + flareSkirtWidth + allowance, y: 20 + lengthVal * scale + allowance },
        { x: 60 + flareSkirtWidth * 0.5, y: 20 + lengthVal * scale + 25 },
        { x: 20 - allowance, y: 20 + lengthVal * scale + allowance },
      ],
    };

    return { svgContent, yardage: ((lengthVal + 16) / 36).toFixed(2) + " Yards", width: flareSkirtWidth + 160, height: lengthVal * scale + 120, segments };
  }
};

/**
 * 🎛️ PHASE 1: IMAGE ANALYSIS ENDPOINT
 */
app.post('/api/analyze-garment', async (req, res) => {
  const { imageBase64 } = req.body;
  if (!imageBase64) return res.status(400).json({ success: false, error: "Missing image payload." });
  const cleanBase64 = imageBase64.includes(",") ? imageBase64.split(",")[1] : imageBase64;

  try {
    console.log("⚡ Groq Vision Engine: Parsing design configuration constraints...");
    const visionResponse = await groq.chat.completions.create({
      model: "meta-llama/llama-4-scout-17b-16e-instruct",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: "Analyze this image. Classify it strictly into one of these structural pattern baselines: 'trousers', 'skirt', 'shirt', 'dress', or 'blouse'. Return JSON structure exactly: {\"categoryKey\": \"blouse\", \"garmentName\": \"Designer Saree Blouse\"}" },
            { type: "image_url", image_url: { url: `data:image/jpeg;base64,${cleanBase64}` } }
          ]
        }
      ],
      temperature: 0.1,
    });

    const parsed = JSON.parse(visionResponse.choices[0].message.content.trim());
    const matchedCategory = parsed.categoryKey.toLowerCase().trim();
    const fieldsDictionary = { trousers: ["waist", "length"], skirt: ["waist", "length"], shirt: ["chest", "length", "sleeveLength"], dress: ["chest", "length"], blouse: ["chest", "length", "frontNeckDepth"] };
    const targetFields = fieldsDictionary[matchedCategory] || fieldsDictionary["dress"];
    console.log(`🎯 Identification Complete: [${parsed.garmentName}] Matched Matrix Type -> [${matchedCategory}]`);

    return res.json({ success: true, garmentName: parsed.garmentName, categoryKey: matchedCategory, fieldsToAsk: targetFields });
  } catch (err) {
    return res.json({ success: false, garmentName: "Custom Garment", categoryKey: "dress", fieldsToAsk: ["chest", "length"] });
  }
});

/**
 * 📐 PHASE 2: PRODUCTION BLUEPRINT GENERATION
 */
app.post('/api/generate-blueprint', async (req, res) => {
  const { measurements, fabricType, imageBase64 } = req.body;
  const garmentName = req.body.garmentName || "";
  let categoryKey = req.body.categoryKey ? req.body.categoryKey.toLowerCase().trim() : null;

  if (!categoryKey || categoryKey === "custom design" || categoryKey === "") {
    const nameLower = (req.body.garmentName || "").toLowerCase();
    if (nameLower.includes("blouse") || nameLower.includes("choli")) categoryKey = "blouse";
    else if (nameLower.includes("skirt")) categoryKey = "skirt";
    else if (nameLower.includes("trouser") || nameLower.includes("pant")) categoryKey = "trousers";
    else if (nameLower.includes("shirt")) categoryKey = "shirt";
    else categoryKey = "dress";
  }
  const selectedFabric = fabricType || "cotton";
  let retrievedContext = tailoringKnowledge.find(k => k.fabricType === selectedFabric.toLowerCase()) || tailoringKnowledge[0];
  const waste = retrievedContext.wasteAdjustmentInches;
  const CANVAS_SCALE = 12;
  const safeCategory = ['trousers', 'skirt', 'shirt', 'dress', 'blouse'].includes(categoryKey) ? categoryKey : "dress";

  try {
    console.log(`📐 Geometrical Drafting Processor: Drawing production-ready patterns for -> [${safeCategory}]`);
    const executeDraftingFormula = DraftingEngine[safeCategory];
    const resultPattern = executeDraftingFormula(measurements || {}, waste, CANVAS_SCALE);

    const cleanMasterSvg = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${resultPattern.width} ${resultPattern.height}" width="100%" height="100%" style="background-color:#ffffff; border: 2px solid #cbd5e1; border-radius:12px;">
        <g transform="translate(15, 45)">${resultPattern.svgContent}</g>
        <text x="35" y="35" style="font-family:sans-serif; font-size:14px; fill:#1a73e8; font-weight:bold; letter-spacing:0.5px;">PRODUCTION PATTERN LAYER: ${(garmentName || safeCategory).toUpperCase()}</text>
        <text x="35" y="${resultPattern.height - 30}" style="font-family:monospace; font-size:13px; fill:#22c55e; font-weight:bold;">■ YARDAGE REQUIRED: ${resultPattern.yardage} (${selectedFabric.toUpperCase()})</text>
      </svg>
    `.trim();

    let tamilInstructionScript = retrievedContext.instructions;
    try {
      const textResponse = await groq.chat.completions.create({
        model: "llama-3.1-8b-instant",
        messages: [{
          role: "user", content: `You are an expert tailoring teacher. Write a short explanation in beautiful, clear spoken Tamil. Do not translate code properties literally.
        Strictly output ONLY these 3 lines and nothing else:

        "முதலில் அளவுகளை சரிபார்த்துக் கொள்ளுங்கள். மார்பு அளவு 36 இன்ச் மற்றும் நீளம் 42 இன்ச் ஆகும்."
        "துணியை வெட்டுவதற்கு வரைபடத்தில் உள்ள நீல நிறக் கோட்டின் மேல் நேராக வெட்ட வேண்டும்."
        "அடுத்து, தையல் போடுவதற்கு சிவப்பு புள்ளி கோட்டின் மீது கவனமாக தையல் போட வேண்டும்."` }],
        temperature: 0.3
      });
      if (textResponse.choices[0].message.content) tamilInstructionScript = textResponse.choices[0].message.content;
    } catch (textErr) {
      console.log("⚠️ Tamil instruction pipeline step fell back.");
    }

    const aiTeacherTrainingData = {
      curriculumBaseline: `How to cut and stitch a professional custom ${safeCategory}`,
      youtubeSearchVideoTrainingTokens: [`how to cut armhole neckline curve sewing pattern ${safeCategory}`],
      videoTimecodeMilestones: { patternMarkingPhase: "00:00 - 04:30", fabricCuttingPhase: "04:31 - 09:15", stitchingAssemblyPhase: "09:16 - End" },
      aiVoiceTeacherScriptTamil: tamilInstructionScript
    };

    return res.json({
      success: true,
      svgBlueprint: cleanMasterSvg,
      fabricSizeRequired: resultPattern.yardage,
      tamilTutorialText: tamilInstructionScript,
      aiTeacherTrainingMetadata: aiTeacherTrainingData,
      categoryKey: safeCategory,
      segments: resultPattern.segments,
      canvasOffset: { x: 15, y: 45 },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, error: "Critical failure occurred while drafting pattern layout coordinates." });
  }
});

/**
 * 🎓 PHASE 3: AI TEACHER LESSON — Script + Multilingual Audio + Animation Timing
 */
const videoLessonJobs = {};

app.post('/api/generate-video-lesson', async (req, res) => {
  const { garmentType, garmentName, measurements, fabricType, languageCode, categoryKey } = req.body;

  if (!garmentType && !categoryKey) {
    return res.status(400).json({ success: false, error: 'garmentType or categoryKey is required.' });
  }

  const sarvamLangMap = { ta: 'ta-IN', en: 'en-IN', hi: 'hi-IN', te: 'te-IN', kn: 'kn-IN' };
  const targetLang = sarvamLangMap[languageCode] || 'ta-IN';

  const safeCategory = ['trousers', 'skirt', 'shirt', 'dress', 'blouse'].includes((categoryKey || '').toLowerCase())
    ? categoryKey.toLowerCase()
    : ['trousers', 'skirt', 'shirt', 'dress', 'blouse'].includes((garmentType || '').toLowerCase())
      ? garmentType.toLowerCase()
      : 'dress';

  const selectedFabric = fabricType || 'cotton';
  const retrievedContext = tailoringKnowledge.find(k => k.fabricType === selectedFabric.toLowerCase()) || tailoringKnowledge[0];
  const waste = retrievedContext.wasteAdjustmentInches;
  const CANVAS_SCALE = 12;

  let resultPattern;
  try {
    resultPattern = DraftingEngine[safeCategory](measurements || {}, waste, CANVAS_SCALE);
  } catch (e) {
    resultPattern = DraftingEngine['dress'](measurements || {}, waste, CANVAS_SCALE);
  }
  const availableSegments = Object.keys(resultPattern.segments || {});

  const videoId = `lesson_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  videoLessonJobs[videoId] = { status: 'processing' };

  res.json({ success: true, videoId });

  try {
    const langName = languageCode === 'ta' ? 'Tamil' : languageCode === 'hi' ? 'Hindi' : languageCode === 'te' ? 'Telugu' : languageCode === 'kn' ? 'Kannada' : 'English';

    const scriptPrompt = `You are a friendly tailoring teacher speaking directly to a student in ${langName}.

Garment Design: ${garmentName || safeCategory}
Garment Category: ${safeCategory}
Fabric: ${selectedFabric}
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
- Order steps in a realistic tailoring sequence: mark/cut outline first, then curves, then seams, then hem, then stitching.`;

    const scriptResponse = await groq.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      response_format: { type: 'json_object' },
      messages: [{ role: 'user', content: scriptPrompt }],
      temperature: 0.4,
    });

    const scriptData = JSON.parse(scriptResponse.choices[0].message.content.trim());
    let steps = scriptData.steps || [];

    steps = steps.map((s) => ({
      ...s,
      segment: availableSegments.includes(s.segment) ? s.segment : (availableSegments[0] || 'outline'),
      action: ['cut', 'pin', 'stitch'].includes(s.action) ? s.action : 'cut',
    }));

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

    videoLessonJobs[videoId] = {
      status: 'completed',
      steps: timedSteps,
      audioBase64,
      totalDurationSec: cursor,
      garmentType: safeCategory,
      languageCode,
      segments: resultPattern.segments,
      canvasOffset: { x: 15, y: 45 },
      canvasSize: { width: resultPattern.width, height: resultPattern.height },
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

/**
 * 👗 AR FIT LAYER ENGINE — FREE HUGGINGFACE SPACE (OFFICIAL IDM-VTON)
 * --------------------------------------------------------------------------
 * 100% FREE — No payment, no GPU, no Colab needed!
 *
 * Uses the official `yisol/IDM-VTON` public space on Hugging Face using
 * the @gradio/client library, which handles queuing and websockets automatically.
 * --------------------------------------------------------------------------
 */

const { Client: GradioClient } = require("@gradio/client");

// Cache the connected client across requests so we don't reconnect every time.
let _vtonClientPromise = null;

function getVtonClient() {
  if (!_vtonClientPromise) {
    const hfToken = process.env.HF_TOKEN; // Optional, doubles quota if provided
    const options = hfToken ? { hf_token: hfToken } : {};
    // Connect to the official public space
    _vtonClientPromise = GradioClient.connect("yisol/IDM-VTON", options);
  }
  return _vtonClientPromise;
}

/**
 * Converts a base64 string into a Blob for Gradio
 */
function base64ToBlob(base64String, mimeType = "image/jpeg") {
  const clean = base64String.includes(",") ? base64String.split(",").pop() : base64String;
  const buffer = Buffer.from(clean, "base64");
  return new Blob([buffer], { type: mimeType });
}

app.post('/api/ar-fit-layer', async (req, res) => {
  const { userPhotoBase64, garmentPatternBase64, clothType } = req.body;

  if (!userPhotoBase64 || !garmentPatternBase64) {
    return res.status(400).json({
      success: false,
      error: "Both userPhotoBase64 and garmentPatternBase64 are required.",
    });
  }

  try {
    console.log("👗 AI Processing: Connecting to official IDM-VTON HuggingFace space...");

    const client = await getVtonClient();

    const personBlob = base64ToBlob(userPhotoBase64);
    const garmentBlob = base64ToBlob(garmentPatternBase64);

    // According to the official API schema:
    // [person_dict, garm_img, garment_des, auto_mask, auto_crop, denoise_steps, seed]
    console.log("  📤 Submitting images to the try-on queue...");
    const result = await client.predict("/tryon", [
      { background: personBlob, layers: [], composite: null }, // person dict
      garmentBlob, // garment image
      "A stylish garment", // garment description
      true, // is_checked (use auto-masking)
      true, // is_checked_crop (auto crop)
      30, // denoise steps
      42, // seed
    ]);

    // Gradio client returns an array of outputs
    const outputImage = result?.data?.[0];
    let resultImageUrl = null;

    if (typeof outputImage === "string") {
      resultImageUrl = outputImage;
    } else if (outputImage?.url) {
      resultImageUrl = outputImage.url;
    }

    if (!resultImageUrl) {
      console.error("⚠️ Unexpected Try-On response shape:", JSON.stringify(result?.data));
      return res.status(502).json({
        success: false,
        error: "Try-on completed but no result image was returned.",
      });
    }

    console.log("✅ Virtual Try-On successful! (Free HF Space)");
    return res.json({ success: true, resultImageUrl });

  } catch (err) {
    console.error("❌ AR Fit Layer Error:", err.message);

    const isQuota = /quota|exceeded|ZeroGPU/i.test(err.message || "");
    const isTimeout = /timeout|ETIMEDOUT/i.test(err.message || "");

    return res.status(500).json({
      success: false,
      error: isQuota
        ? "Free GPU quota exceeded on HuggingFace for today. Try again later."
        : isTimeout
          ? "The server took too long to respond. The free queue might be full."
          : `Virtual Try-On failed: ${err.message}`,
    });
  }
});

/**
 * 🎨 PHASE 4: PERSONALIZED STYLE RECOMMENDER
 */
app.post('/api/recommend-style', async (req, res) => {
  const { image } = req.body;
  if (!image) return res.status(400).json({ success: false, error: "Missing image payload." });
  const cleanBase64 = image.includes(",") ? image.split(",")[1] : image;

  try {
    console.log("⚡ Groq Vision Engine: Generating style recommendation based on user photo...");
    const visionResponse = await groq.chat.completions.create({
      model: "meta-llama/llama-4-scout-17b-16e-instruct",
      response_format: { type: "json_object" },
      messages: [
        {
          role: "user",
          content: [
            { 
              type: "text", 
              text: "Analyze the user's photo. Recommend a clothing style that would suit them best (e.g., 'Designer Saree Blouse', 'Casual Linen Shirt', 'Anarkali Salwar Kameez', 'Flared Dress', etc.). Return JSON structure: {\"recommended_type\": \"Designer Saree Blouse\"}" 
            },
            { type: "image_url", image_url: { url: `data:image/jpeg;base64,${cleanBase64}` } }
          ]
        }
      ],
      temperature: 0.7,
    });

    const parsed = JSON.parse(visionResponse.choices[0].message.content.trim());
    return res.json({ success: true, recommended_type: parsed.recommended_type });
  } catch (err) {
    console.error("Style recommend error:", err);
    return res.json({ success: true, recommended_type: "Casual Linen Shirt" }); // Fallback
  }
});

/**
 * 🌸 PHASE 5: AI AARI EMBROIDERY DESIGN RECOMMENDER
 */
app.post('/api/recommend-aari', async (req, res) => {
  const { dressType, occasion, fabricType, userRequirements } = req.body;

  try {
    console.log("🌸 Groq Engine: Generating Aari embroidery recommendations...");
    const prompt = `Recommend 3 specific, detailed Aari embroidery work designs based on the following requirements:
Dress Type: ${dressType || 'Any'}
Occasion: ${occasion || 'Any'}
Fabric: ${fabricType || 'Any'}
User requirements: ${userRequirements || 'None'}

Return ONLY valid JSON format with three recommendations. Return exactly in this structure (do not add any markdown, wrapper, or trailing text):
{
  "recommendations": [
    {
      "emoji": "🌸",
      "name": "Design Name",
      "style": "Thread / Zari / Mirror / Zardozi",
      "difficulty": "Beginner / Intermediate / Advanced",
      "desc": "Short description of the design",
      "materials": ["Gold zari thread", "Stone chain", "Beads"],
      "instructions": "1. Trace the pattern. 2. Start chain stitch."
    }
  ]
}`;

    const response = await groq.chat.completions.create({
      model: "llama-3.1-8b-instant",
      response_format: { type: "json_object" },
      messages: [{ role: "user", content: prompt }],
      temperature: 0.7,
    });

    const data = JSON.parse(response.choices[0].message.content.trim());
    return res.json({ success: true, recommendations: data.recommendations });
  } catch (err) {
    console.error("Aari recommendation error:", err);
    return res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Ready-To-Cut Universal Vector Pipeline active on port ${PORT}`);
});