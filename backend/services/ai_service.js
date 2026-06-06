const axios = require('axios');

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

/**
 * Analyzes lesson text and extracts summary, topics, and objectives.
 */
exports.analyzeLesson = async (lessonText) => {
    try {
        if (!process.env.GEMINI_API_KEY) {
            throw new Error('GEMINI_API_KEY not found.');
        }

        const prompt = `You are a strict educational assistant for SCIMATHIX. You must ONLY process content related to Science and Mathematics at a Grade 9 level. 
Analyze the provided lesson text. If the text is NOT related to Grade 9 Math or Science, return a generic summary declining the analysis. 
If it is valid, return a JSON object ONLY. Do not include markdown formatting or backticks. The JSON object must have:
- 'summary' (string): A simple, easy-to-understand summary for a Grade 9 student.
- 'topics' (array of strings)
- 'learningObjectives' (array of strings)

Lesson Text:
${lessonText}`;

        const response = await axios.post(`${GEMINI_API_URL}?key=${process.env.GEMINI_API_KEY}`, {
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
                responseMimeType: "application/json",
            }
        });

        const rawText = response.data.candidates[0].content.parts[0].text;
        return JSON.parse(rawText);
    } catch (error) {
        console.error('AI Analysis Error:', error.response ? error.response.data : error.message);
        const cleanedText = String(lessonText || '').replace(/\s+/g, ' ').trim();
        const summary = cleanedText
            ? cleanedText.slice(0, 450) + (cleanedText.length > 450 ? '...' : '')
            : 'The lesson was saved successfully. Analysis might be unavailable at the moment, but you can still read the lesson content.';

        return {
            summary,
            topics: ["General Topic"],
            learningObjectives: [
                "Understand the core concepts presented in this lesson.",
                "Review the material to prepare for upcoming quizzes.",
            ]
        };
    }
};

/**
 * Generates randomized quiz questions based on lesson content.
 */
const _questionImage = (label = 'Grade 9 Quiz') => {
    const safeLabel = String(label).slice(0, 42).replace(/[<>&"]/g, '');
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="900" height="360" viewBox="0 0 900 360"><rect width="900" height="360" fill="#eef7ff"/><circle cx="760" cy="80" r="96" fill="#bfdbfe"/><circle cx="120" cy="290" r="130" fill="#bbf7d0"/><rect x="80" y="74" width="520" height="210" rx="28" fill="#ffffff" stroke="#93c5fd" stroke-width="6"/><text x="122" y="145" font-family="Arial" font-size="34" font-weight="700" fill="#0f172a">Grade 9 Visual Guide</text><text x="122" y="205" font-family="Arial" font-size="28" fill="#0f766e">${safeLabel}</text><path d="M675 220 l55-95 l55 95 z" fill="#38bdf8" opacity=".9"/><rect x="660" y="230" width="145" height="28" rx="14" fill="#0f766e" opacity=".8"/></svg>`;
    return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
};

const cleanSentence = (value) => String(value || '')
    .replace(/\s+/g, ' ')
    .replace(/^[\W_]+|[\W_]+$/g, '')
    .trim();

const getLessonSentences = (lessonText) => {
    const cleaned = String(lessonText || '').replace(/\s+/g, ' ').trim();
    return cleaned
        .split(/(?<=[.!?])\s+/)
        .map(cleanSentence)
        .filter(sentence => sentence.length >= 35 && sentence.length <= 220)
        .filter(sentence => !/^https?:\/\//i.test(sentence));
};

const getFallbackOptions = (sentences, correctAnswer, index) => {
    const options = [correctAnswer];
    for (const sentence of sentences) {
        if (options.length >= 4) break;
        if (sentence !== correctAnswer && !options.includes(sentence)) options.push(sentence);
    }

    const genericOptions = [
        'The lesson describes how body systems work together.',
        'The lesson explains an important Science concept.',
        'The lesson connects the topic to real-life examples.',
        'The lesson identifies key facts students should remember.',
    ];

    for (const option of genericOptions) {
        if (options.length >= 4) break;
        if (!options.includes(option)) options.push(option);
    }

    const rotation = index % options.length;
    return [...options.slice(rotation), ...options.slice(0, rotation)];
};

const getContentBasedQuiz = (lessonTitle, lessonText, count, type = 'Multiple Choice') => {
    const selectedTypes = Array.isArray(type) && type.length > 0 ? type : [type || 'Multiple Choice'];
    const sentences = getLessonSentences(lessonText);
    if (sentences.length === 0) return [];

    return Array.from({ length: count }, (_, index) => {
        const requestedType = selectedTypes[index % selectedTypes.length];
        const correctAnswer = sentences[index % sentences.length];
        const imageUrl = _questionImage(lessonTitle);

        if (requestedType === 'True/False') {
            return {
                baseQuestion: `True or False: ${correctAnswer}`,
                variables: {},
                type: 'multiple-choice',
                optionsTemplate: ['True', 'False'],
                correctAnswerTemplate: 'True',
                explanationTemplate: `This statement appears in the lesson content: ${correctAnswer}`,
                solutionSteps: ['Read the statement carefully.', 'Compare it with the lesson text.'],
                imageUrl
            };
        }

        if (requestedType === 'Problem Solving') {
            return {
                baseQuestion: `Based on the lesson, name one key idea related to "${lessonTitle}".`,
                variables: {},
                type: 'identification',
                optionsTemplate: [],
                correctAnswerTemplate: correctAnswer,
                explanationTemplate: `One acceptable answer is based on this lesson statement: ${correctAnswer}`,
                solutionSteps: ['Review the lesson text.', 'Write a key idea from the lesson.'],
                imageUrl
            };
        }

        return {
            baseQuestion: 'According to the lesson, which statement is correct?',
            variables: {},
            type: 'multiple-choice',
            optionsTemplate: getFallbackOptions(sentences, correctAnswer, index),
            correctAnswerTemplate: correctAnswer,
            explanationTemplate: `The correct statement is taken directly from the lesson: ${correctAnswer}`,
            solutionSteps: ['Look for the statement supported by the lesson.', 'Choose the option that matches the lesson content.'],
            imageUrl
        };
    });
};

exports.generateQuiz = async (lessonTitle, lessonSummary, count = 5, type = 'Multiple Choice') => {
    try {
        if (!process.env.GEMINI_API_KEY) {
            return getContentBasedQuiz(lessonTitle, lessonSummary, count, type);
        }

        const selectedTypes = Array.isArray(type) && type.length > 0 ? type : [type || 'Multiple Choice'];
        const typeInstruction = selectedTypes.join(', ');

        const prompt = `You are a strict Math and Science teacher for Grade 9 students in the Philippines. Create exactly ${count} VERY EASY quiz questions using these allowed question types: ${typeInstruction}.
Ensure the questions are suitable for the Philippine high school education system. The difficulty should be set to very easy (about 30% difficulty relative to standard). Focus on fundamental concepts and straightforward phrasing.
Base every question STRICTLY and ONLY on the provided lesson content. Do not use generic placeholders. Do not use "Option A", "Option B", "Sample question", or similar filler text.
Return ONLY a JSON array of objects. Each object must have: 
- 'question' (string): Simple, Grade-9 appropriate question.
- 'type' (string: exactly one of "Multiple Choice", "True/False", or "Problem Solving")
- 'options' (array: exactly 4 real answer choices for Multiple Choice, exactly ["True","False"] for True/False, and [] for Problem Solving)
- 'correctAnswer' (string, must exactly match one of the options for Multiple Choice or True/False, or be a numeric/short answer for Problem Solving)
- 'explanation' (string): Simple explanation understandable by a 14-year-old.
- 'solutionSteps' (array of 2 to 4 short strings; required for problem solving, useful for all)
Use short numbers and one-step or two-step computations only. Avoid hard factoring, trigonometry, and advanced formulas.

Lesson Title: ${lessonTitle}

Lesson Content:
${lessonSummary}`;

        const response = await axios.post(`${GEMINI_API_URL}?key=${process.env.GEMINI_API_KEY}`, {
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
                responseMimeType: "application/json",
            }
        });

        const rawText = response.data.candidates[0].content.parts[0].text;
        const parsed = JSON.parse(rawText);
        
        // Map the Gemini output to our Quiz format
        return parsed.map(q => ({
            baseQuestion: q.question,
            variables: {},
            type: q.type === 'Problem Solving' ? 'problem-solving' : 'multiple-choice',
            optionsTemplate: q.options || [],
            correctAnswerTemplate: q.correctAnswer,
            explanationTemplate: q.explanation,
            solutionSteps: q.solutionSteps || [],
            imageUrl: _questionImage(lessonTitle)
        }));
    } catch (error) {
        console.error('AI Quiz Generation Error:', error.response ? error.response.data : error.message);
        return getContentBasedQuiz(lessonTitle, lessonSummary, count, type);
    }
};
