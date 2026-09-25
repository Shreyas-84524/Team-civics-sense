import '../../models/category_model.dart';

/// Prompt templates for CivicFix multimodal visual evidence verification.
class CivicVerificationPrompt {
  CivicVerificationPrompt._();

  /// Standard diagnostic prompt for visual analysis (Phase 2 proof-of-connection baseline).
  static const String diagnosticPrompt = '''
You are the visual verification assistant for CivicFix, a municipal civic grievance platform.
Please analyze the attached photographic evidence submitted with a citizen civic issue report.

Perform the following visual analysis:
1. Describe what is visibly present in the image.
2. Identify whether the image appears relevant to a public municipal or civic issue (e.g. road damage, garbage overflow, water leakage, broken streetlights, traffic infrastructure, sanitation, or public safety hazard).
3. List the obvious objects, infrastructure elements, or visible defects in the scene.
4. Keep your response concise, objective, and factual (2 to 4 sentences).

Do not make a final decision to accept or reject the complaint. Focus strictly on describing what is visually evident.
''';

  /// Builds a structured prompt for Phase 3 civic verification using the citizen-selected [CivicCategory].
  static String buildPrompt({required CivicCategory selectedCategory}) {
    return '''
You are CivicFix's visual civic-evidence verification assistant.
A citizen has submitted a public grievance report under the category: "${selectedCategory.name}" (ID: "${selectedCategory.id}").
Category Description: "${selectedCategory.description}".

Analyze the attached photographic evidence against this selected category and evaluate its civic validity, usability, and safety hazards.

Rules & Guidelines:
1. Analyze ONLY what is directly visible in the image.
2. Do not invent objects, defects, or hazards not present in the photo.
3. Do not infer hidden information outside the frame.
4. Do not identify people, faces, or private individuals.
5. Do not make legal conclusions or determine citizen intent.
6. Category matching and evidence usability are advisory metrics.
7. If the image is a synthetic graphic, blank/solid color, screenshot without real-world context, or completely unreadable, set "is_usable_evidence" to false, "category_match" to false, and "is_hazard" to false.
8. If the image depicts a real civic problem belonging to a different category than "${selectedCategory.name}", set "category_match" to false, set "is_usable_evidence" to true, and set "detected_category" to the actual category observed.
9. If the image depicts a legitimate civic problem matching "${selectedCategory.name}", set "category_match" to true and "is_usable_evidence" to true.
10. Hazard severity ("none", "low", "medium", "high", "unknown") and type must be strictly based on visible risk.
11. Keep "detected_objects" concise (max 10 relevant items).
12. All confidence values must be numeric between 0.0 and 1.0.

Produce output conforming to the provided structured JSON response schema.
''';
  }
}
