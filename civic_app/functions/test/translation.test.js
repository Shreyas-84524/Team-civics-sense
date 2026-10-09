const { describe, it } = require('node:test');
const assert = require('node:assert');

const {
  isSupportedLanguage,
  computeSourceHash,
  computeCacheDocId,
  generateGlossaryPrompt,
  simulateOfflineTranslation,
  SUPPORTED_LANGUAGES,
  CURRENT_TRANSLATION_VERSION,
  CIVIC_GLOSSARY,
} = require('../lib/translation');

describe('Multilingual Production Translation Module (functions/src/translation.ts)', () => {
  describe('Supported Languages & Strict Allowlist', () => {
    it('supports only English, Hindi, and Marathi', () => {
      assert.deepStrictEqual([...SUPPORTED_LANGUAGES], ['en', 'hi', 'mr']);
      assert.strictEqual(isSupportedLanguage('en'), true);
      assert.strictEqual(isSupportedLanguage('hi'), true);
      assert.strictEqual(isSupportedLanguage('mr'), true);
      assert.strictEqual(isSupportedLanguage('EN'), true);
      assert.strictEqual(isSupportedLanguage('hi_IN'), false);
      assert.strictEqual(isSupportedLanguage('fr'), false);
      assert.strictEqual(isSupportedLanguage('es'), false);
      assert.strictEqual(isSupportedLanguage(''), false);
      assert.strictEqual(isSupportedLanguage(null), false);
    });
  });

  describe('Deterministic Source Hash & Cache Key Calculation', () => {
    it('computes consistent SHA-256 source hash', () => {
      const text1 = 'There is water leakage near the school.';
      const text2 = '  There is water leakage near the school.  ';
      const hash1 = computeSourceHash(text1);
      const hash2 = computeSourceHash(text2);
      assert.strictEqual(hash1, hash2);
      assert.strictEqual(hash1.length, 64);
    });

    it('computes unique cache doc ID isolating target languages, content types, and versions', () => {
      const sourceHash = computeSourceHash('Pothole on Main Road');

      const keyEnToMrV1 = computeCacheDocId({
        contentType: 'complaint_title',
        sourceHash,
        sourceLanguage: 'en',
        targetLanguage: 'mr',
        version: CURRENT_TRANSLATION_VERSION,
      });

      const keyEnToHiV1 = computeCacheDocId({
        contentType: 'complaint_title',
        sourceHash,
        sourceLanguage: 'en',
        targetLanguage: 'hi',
        version: CURRENT_TRANSLATION_VERSION,
      });

      const keyEnToMrV2 = computeCacheDocId({
        contentType: 'complaint_title',
        sourceHash,
        sourceLanguage: 'en',
        targetLanguage: 'mr',
        version: 2,
      });

      assert.notStrictEqual(keyEnToMrV1, keyEnToHiV1, 'Target languages must have distinct cache keys');
      assert.notStrictEqual(keyEnToMrV1, keyEnToMrV2, 'Versions must have distinct cache keys');
      assert.strictEqual(keyEnToMrV1.length, 64);
    });
  });

  describe('Civic Terminology Glossary', () => {
    it('contains approved municipal terms across English, Hindi, and Marathi', () => {
      assert.strictEqual(CIVIC_GLOSSARY.complaint.mr, 'तक्रार');
      assert.strictEqual(CIVIC_GLOSSARY.complaint.hi, 'शिकायत');
      assert.strictEqual(CIVIC_GLOSSARY.ward.mr, 'प्रभाग');
      assert.strictEqual(CIVIC_GLOSSARY.ward.hi, 'वार्ड');
      assert.strictEqual(CIVIC_GLOSSARY.pothole.mr, 'खड्डा');
      assert.strictEqual(CIVIC_GLOSSARY.pothole.hi, 'गड्ढा');
      assert.strictEqual(CIVIC_GLOSSARY.waterLeakage.mr, 'पाण्याची गळती');
      assert.strictEqual(CIVIC_GLOSSARY.waterLeakage.hi, 'पानी का रिसाव');
    });

    it('generates compact glossary prompt for target languages', () => {
      const mrGlossary = generateGlossaryPrompt('mr');
      assert.ok(mrGlossary.includes('खड्डा'));
      assert.ok(mrGlossary.includes('तक्रार'));

      const hiGlossary = generateGlossaryPrompt('hi');
      assert.ok(hiGlossary.includes('गड्ढा'));
      assert.ok(hiGlossary.includes('शिकायत'));
    });
  });

  describe('Offline Simulated Translations & All 6 Translation Directions', () => {
    it('handles same-language identity bypass', () => {
      const text = 'Clean street in Ward A';
      assert.strictEqual(simulateOfflineTranslation(text, 'en', 'en'), text);
      assert.strictEqual(simulateOfflineTranslation('तक्रार', 'mr', 'mr'), 'तक्रार');
    });

    it('translates across all 6 directional permutations safely', () => {
      const en = 'There is water leakage near the school.';
      const mr = simulateOfflineTranslation(en, 'en', 'mr');
      const hi = simulateOfflineTranslation(en, 'en', 'hi');

      assert.strictEqual(mr, 'शाळेजवळ पाण्याची गळती आहे.');
      assert.strictEqual(hi, 'स्कूल के पास पानी का रिसाव है।');

      // mr -> en, mr -> hi
      assert.strictEqual(simulateOfflineTranslation(mr, 'mr', 'en'), 'There is water leakage near the school.');
      assert.strictEqual(simulateOfflineTranslation(mr, 'mr', 'hi'), 'स्कूल के पास पानी का रिसाव है।');

      // hi -> en, hi -> mr
      assert.strictEqual(simulateOfflineTranslation(hi, 'hi', 'en'), 'There is water leakage near the school.');
      assert.strictEqual(simulateOfflineTranslation(hi, 'hi', 'mr'), 'शाळेजवळ पाण्याची गळती आहे.');
    });
  });
});
