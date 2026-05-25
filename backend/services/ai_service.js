const axios = require('axios');

const DEEPSEEK_API_URL = 'https://api.deepseek.com/v1/chat/completions';

/**
 * Analyzes lesson text and extracts summary, topics, and objectives.
 */
exports.analyzeLesson = async (lessonText) => {
    try {
        if (!process.env.DEEPSEEK_API_KEY) {
            console.warn('DEEPSEEK_API_KEY not found. Using mock analysis.');
            return {
                summary: "This is a mock summary of the lesson content provided.",
                topics: ["General Topic", "Key Concept"],
                learningObjectives: ["Understand the basic principles.", "Apply concepts in practice."]
            };
        }

        const response = await axios.post(DEEPSEEK_API_URL, {
            model: "deepseek-chat",
            messages: [
                {
                    role: "system",
                    content: "You are an educational assistant for SCIMATHNIX. Analyze the provided lesson text and return a JSON object with 'summary', 'topics' (array), and 'learningObjectives' (array)."
                },
                {
                    role: "user",
                    content: lessonText
                }
            ],
            response_format: { type: "json_object" }
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        return JSON.parse(response.data.choices[0].message.content);
    } catch (error) {
        console.error('AI Analysis Error:', error.response ? error.response.data : error.message);
        // Fallback to mock if API fails
        return {
            summary: "Analysis failed, but the lesson was saved successfully.",
            topics: ["Uncategorized"],
            learningObjectives: ["Review the uploaded content."]
        };
    }
};

/**
 * Generates randomized quiz questions based on lesson content.
 */
exports.generateQuiz = async (lessonTitle, lessonSummary, count = 5) => {
    try {
        if (!process.env.DEEPSEEK_API_KEY) {
            return _getMockQuiz(count);
        }

        const response = await axios.post(DEEPSEEK_API_URL, {
            model: "deepseek-reasoner",
            messages: [
                {
                    role: "system",
                    content: `You are a math and science teacher. Create ${count} quiz questions based on the lesson: ${lessonTitle}. 
                    Return as a JSON array of objects.`
                },
                {
                    role: "user",
                    content: `Lesson Summary: ${lessonSummary}`
                }
            ],
            response_format: { type: "json_object" }
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        return JSON.parse(response.data.choices[0].message.content);
    } catch (error) {
        console.error('AI Quiz Generation Error:', error.response ? error.response.data : error.message);
        return _getMockQuiz(count);
    }
};

const _getMockQuiz = (count) => {
    return Array.from({ length: count }, (_, i) => ({
        baseQuestion: `Sample question ${i + 1} for this topic?`,
        variables: {},
        type: 'multiple-choice',
        correctAnswerTemplate: 'Option A',
        explanationTemplate: 'Basic explanation.'
    }));
};
