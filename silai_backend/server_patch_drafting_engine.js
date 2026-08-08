/**
 * 📐 DRAFTING ENGINE PATCH — Named Segment Export
 * --------------------------------------------------------------------------
 * WHY THIS FILE EXISTS:
 * Your existing DraftingEngine functions (blouse, shirt, trousers, skirt,
 * dress) build ONE big SVG path string internally and return only the
 * final merged `svgContent`. That's enough to DRAW the blueprint, but not
 * enough to ANIMATE a specific region of it — Flutter has no way to know
 * where "the armhole curve" or "the waistline" actually sits in canvas
 * coordinates.
 *
 * THE FIX:
 * Each drafting function below additionally computes and returns a
 * `segments` object — named key points / sub-paths in the SAME coordinate
 * space as the SVG. The Flutter side will:
 *   1. Receive `segments` alongside `svgContent` (already wired into the
 *      /api/generate-blueprint response below)
 *   2. Match each narration step's `highlight` + matched segment name to
 *      the correct points
 *   3. Animate the scissors/needle to travel exactly along those points
 *
 * HOW TO APPLY:
 * Replace your existing `DraftingEngine` object in server.js with this one.
 * The math for the visible SVG paths is UNCHANGED — only `segments` is new.
 * Your /api/generate-blueprint route needs ONE line added (shown at the
 * bottom of this file) to pass `segments` through in the JSON response.
 * --------------------------------------------------------------------------
 */

const DraftingEngine = {
  // 1. TAILORED SAREE BLOUSE / CROP TOP
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
      <path d="M 50,20 
               L ${50 + shoulderWidth},15 
               C ${50 + shoulderWidth + 15},${15 + armholeDepth * 0.5} ${50 + mainWidth + allowance - 5},${20 + armholeDepth * 0.8} ${50 + mainWidth + allowance},${20 + armholeDepth} 
               L ${50 + mainWidth + allowance - 15},${20 + totalHeight + allowance} 
               L ${50 - allowance},${20 + totalHeight + allowance} 
               C ${50 - allowance},${20 + totalHeight * 0.5} 50,${20 + neckDepth * scale + allowance} 50,20 Z" 
            style="stroke:#1a73e8; stroke-width:3; fill:#fdfdfd;" />
               
      <path d="M 50,20 
               L ${50 + shoulderWidth},20 
               C ${50 + shoulderWidth},${20 + armholeDepth * 0.5} ${50 + mainWidth - 5},${20 + armholeDepth * 0.8} ${50 + mainWidth},${20 + armholeDepth} 
               L ${50 + mainWidth - 12},${20 + totalHeight} 
               L 50,${20 + totalHeight} 
               C 50,${20 + totalHeight * 0.5} 50,${20 + neckDepth * scale} 50,20 Z" 
            style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
               
      <path d="M ${50 + dartLocationX - 10},${20 + totalHeight} L ${50 + dartLocationX},${20 + totalHeight * 0.55} L ${50 + dartLocationX + 10},${20 + totalHeight}" style="stroke:#e67e22; stroke-width:2; fill:none;" />
      
      ${cmTicks}
      <text x="60" y="${20 + armholeDepth + 20}" font-family="sans-serif" font-size="11px" fill="#1a73e8" font-weight="bold">✂️ CUT ALONG ARMHOLE CURVE</text>
    `;

    // Named segments — same coordinate space as svgContent above.
    // Each is a polyline approximation good enough for smooth animation.
    const segments = {
      neckline: [
        { x: 50, y: 20 },
        { x: 50, y: 20 + neckDepth * scale * 0.5 },
        { x: 50, y: 20 + neckDepth * scale },
      ],
      shoulder: [
        { x: 50, y: 20 },
        { x: 50 + shoulderWidth, y: 20 },
      ],
      armhole_curve: [
        { x: 50 + shoulderWidth, y: 20 },
        { x: 50 + mainWidth * 0.85, y: 20 + armholeDepth * 0.45 },
        { x: 50 + mainWidth, y: 20 + armholeDepth },
      ],
      side_seam: [
        { x: 50 + mainWidth, y: 20 + armholeDepth },
        { x: 50 + mainWidth - 12, y: 20 + totalHeight },
      ],
      hemline: [
        { x: 50 + mainWidth - 12, y: 20 + totalHeight },
        { x: 50 + dartLocationX, y: 20 + totalHeight },
        { x: 50, y: 20 + totalHeight },
      ],
      dart: [
        { x: 50 + dartLocationX - 10, y: 20 + totalHeight },
        { x: 50 + dartLocationX, y: 20 + totalHeight * 0.55 },
        { x: 50 + dartLocationX + 10, y: 20 + totalHeight },
      ],
    };

    return { svgContent, yardage: "1.00 Yards", width: mainWidth + 120, height: totalHeight + 100, segments };
  },

  // 2. SHIRTS / KURTAS / TUNICS
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
      <path d="M ${40 + neckScoopX},20 
               L ${40 + bodyWidth * 0.85},${20 + shoulderSlope} 
               C ${40 + bodyWidth * 0.75},${20 + armholeCurveDepth * 0.5} ${40 + bodyWidth + allowance},${20 + armholeCurveDepth * 0.8} ${40 + bodyWidth + allowance},${20 + armholeCurveDepth} 
               L ${40 + bodyWidth + allowance},${20 + bodyHeight + allowance} 
               L ${40 - allowance},${20 + bodyHeight + allowance} 
               L ${40 - allowance},${20 + neckScoopY} 
               Q 40,20 ${40 + neckScoopX},20 Z" style="stroke:#1a73e8; stroke-width:3; fill:#f9fbfd;" />

      <path d="M ${40 + neckScoopX},20 
               L ${40 + bodyWidth * 0.85},${20 + shoulderSlope} 
               C ${40 + bodyWidth * 0.75},${20 + armholeCurveDepth * 0.5} ${40 + bodyWidth},${20 + armholeCurveDepth * 0.8} ${40 + bodyWidth},${20 + armholeCurveDepth} 
               L ${40 + bodyWidth},${20 + bodyHeight} 
               L 40,${20 + bodyHeight} 
               L 40,${20 + neckScoopY} 
               Q 40,20 ${40 + neckScoopX},20 Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />

      <path d="M ${80 + bodyWidth},20 
               L ${80 + bodyWidth + sleeveWidth},20 
               L ${80 + bodyWidth + sleeveWidth},${20 + sleeveHeight} 
               L ${80 + bodyWidth + 30},${20 + sleeveHeight} 
               C ${80 + bodyWidth + 20},${20 + armholeCurveDepth} ${80 + bodyWidth},${20 + armholeCurveDepth * 0.5} ${80 + bodyWidth},20 Z" 
            style="stroke:#1a73e8; stroke-width:3; fill:#f9fbfd;" />

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
        { x: 40 + bodyWidth * 0.92, y: 20 + armholeCurveDepth * 0.6 },
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
      ],
    };

    return { svgContent, yardage: ((lengthVal + sleeveVal + 6) / 36).toFixed(2) + " Yards", width: (bodyWidth * 2.5) + 150, height: Math.max(bodyHeight, sleeveHeight) + 100, segments };
  },

  // 3. TROUSERS / PANTS / SALWARS / JEANS
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
      <path d="M 40,20 
               L ${40 + waistWidth},20 
               L ${40 + hipWidth},${20 + crotchDepth * 0.4} 
               C ${40 + hipWidth},${20 + crotchDepth * 0.7} ${40 + waistWidth + 30},${20 + crotchDepth} ${40 + waistWidth + 45 + allowance},${20 + crotchDepth} 
               L ${40 + kneeWidth + allowance},${20 + (lengthVal * 0.55) * scale} 
               L ${40 + bottomAnkleWidth + allowance},${20 + lengthVal * scale + allowance} 
               L ${40 - allowance},${20 + lengthVal * scale + allowance} Z" style="stroke:#1a73e8; stroke-width:3; fill:#fdfdfd;" />
               
      <path d="M 40,20 
               L ${40 + waistWidth},20 
               L ${40 + hipWidth - allowance},${20 + crotchDepth * 0.4} 
               C ${40 + hipWidth - allowance},${20 + crotchDepth * 0.7} ${40 + waistWidth + 30},${20 + crotchDepth} ${40 + waistWidth + 45},${20 + crotchDepth} 
               L ${40 + kneeWidth},${20 + (lengthVal * 0.55) * scale} 
               L ${40 + bottomAnkleWidth},${20 + lengthVal * scale} 
               L 40,${20 + lengthVal * scale} Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
               
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
        { x: 40 + waistWidth + 30, y: 20 + crotchDepth * 0.85 },
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

  // 4. SKIRTS / MAXI SKIRTS / LEHENGAS
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
      <path d="M 80,30 
               Q ${80 + waistQuarter * 0.5},${30 + 15} ${80 + waistQuarter + allowance},30 
               L ${40 + baseSweepWidth + allowance},${30 + lengthVal * scale + allowance} 
               Q ${40 + baseSweepWidth * 0.5},${30 + lengthVal * scale + 20} ${40 - allowance},${30 + lengthVal * scale + allowance} Z" style="stroke:#1a73e8; stroke-width:3; fill:#fdfdfd;" />
      
      <path d="M 80,30 
               Q ${80 + waistQuarter * 0.5},${30 + 10} ${80 + waistQuarter},30 
               L ${40 + baseSweepWidth},${30 + lengthVal * scale} 
               Q ${40 + baseSweepWidth * 0.5},${30 + lengthVal * scale + 10} 40,${30 + lengthVal * scale} Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
               
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

  // 5. FULL DRESSES / FROCKS / GOWNS / ANARKALIS
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
      <path d="M 60,20 
               L ${60 + shoulderWidth},15 
               C ${60 + shoulderWidth + 15},${15 + armholeDepth * 0.5} ${60 + frontWidth + allowance},${20 + armholeDepth * 0.8} ${60 + frontWidth + allowance},${20 + armholeDepth} 
               L ${60 + frontWidth + allowance - 10},${20 + naturalBodiceHeight} 
               L ${60 + flareSkirtWidth + allowance},${20 + lengthVal * scale + allowance} 
               Q ${60 + flareSkirtWidth * 0.5},${20 + lengthVal * scale + 25} ${20 - allowance},${20 + lengthVal * scale + allowance} 
               L ${60 - allowance},${20 + naturalBodiceHeight} Z" style="stroke:#1a73e8; stroke-width:3; fill:#fdfdfd;" />
               
      <path d="M 60,20 
               L ${60 + shoulderWidth},20 
               C ${60 + shoulderWidth},${20 + armholeDepth * 0.5} ${60 + frontWidth},${20 + armholeDepth * 0.8} ${60 + frontWidth},${20 + armholeDepth} 
               L ${60 + frontWidth - 8},${20 + naturalBodiceHeight} 
               L ${60 + flareSkirtWidth},${20 + lengthVal * scale} 
               Q ${60 + flareSkirtWidth * 0.5},${20 + lengthVal * scale + 15} 20,${20 + lengthVal * scale} 
               L 60,${20 + naturalBodiceHeight} Z" style="stroke:#d93025; stroke-width:1.5; stroke-dasharray:6,4; fill:none;" />
               
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
        { x: 60 + frontWidth * 0.9, y: 20 + armholeDepth * 0.55 },
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
  },
};

module.exports = DraftingEngine;

/**
 * --------------------------------------------------------------------------
 * ONE-LINE CHANGE NEEDED in your /api/generate-blueprint route:
 * --------------------------------------------------------------------------
 * Find this block:
 *
 *   const resultPattern = executeDraftingFormula(measurements || {}, waste, CANVAS_SCALE);
 *   ...
 *   return res.json({
 *     success: true,
 *     svgBlueprint: cleanMasterSvg,
 *     fabricSizeRequired: resultPattern.yardage,
 *     tamilTutorialText: tamilInstructionScript,
 *     aiTeacherTrainingMetadata: aiTeacherTrainingData
 *   });
 *
 * Add ONE field to the response — resultPattern.segments:
 *
 *   return res.json({
 *     success: true,
 *     svgBlueprint: cleanMasterSvg,
 *     fabricSizeRequired: resultPattern.yardage,
 *     tamilTutorialText: tamilInstructionScript,
 *     aiTeacherTrainingMetadata: aiTeacherTrainingData,
 *     segments: resultPattern.segments,        // <-- ADD THIS LINE
 *     canvasOffset: { x: 15, y: 45 }            // <-- ADD THIS: matches your
 *                                                //     <g transform="translate(15, 45)">
 *   });
 *
 * The canvasOffset matters because your cleanMasterSvg wraps the pattern in
 * <g transform="translate(15, 45)">. The segment coordinates above are in
 * the UN-translated local space, so Flutter needs to add this offset before
 * drawing the scissors/needle path on top of the rendered SVG.
 * --------------------------------------------------------------------------
 */