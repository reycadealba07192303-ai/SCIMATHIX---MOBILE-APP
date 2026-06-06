const { evaluate } = require('mathjs');

/**
 * Takes a question template and a set of variables, and returns a randomized version.
 */
exports.randomizeQuestion = (question) => {
    const randomizedValues = {};
    let questionText = question.baseQuestion;
    let answerFormula = question.correctAnswerTemplate;
    let explanation = question.explanationTemplate || "";
    let options = question.optionsTemplate ? [...question.optionsTemplate] : [];

    // 1. Pick a random value for each variable
    // Check if variables is a Map or an Object
    const vars = question.variables instanceof Map ? Object.fromEntries(question.variables) : question.variables;

    for (const [key, values] of Object.entries(vars)) {
        if (Array.isArray(values) && values.length > 0) {
            const randomIndex = Math.floor(Math.random() * values.length);
            const chosenValue = values[randomIndex];
            randomizedValues[key] = chosenValue;

            const regex = new RegExp(`{${key}}`, 'g');
            questionText = questionText.replace(regex, chosenValue);
            answerFormula = answerFormula.replace(regex, chosenValue);
            explanation = explanation.replace(regex, chosenValue);
            options = options.map(opt => opt.replace(regex, chosenValue));
        }
    }

    // 2. Calculate the actual answer
    let actualAnswer;
    try {
        actualAnswer = evaluate(answerFormula);
        if (typeof actualAnswer === 'number') {
            actualAnswer = Math.round(actualAnswer * 100) / 100;
        }
    } catch (e) {
        actualAnswer = answerFormula;
    }

    // Process options to evaluate formulas if applicable
    options = options.map(opt => {
        try {
            const evaluated = evaluate(opt);
            if (typeof evaluated === 'number') {
                return Math.round(evaluated * 100) / 100;
            }
            return evaluated;
        } catch (e) {
            return opt;
        }
    });

    return {
        _id: question._id,
        text: questionText,
        type: question.type,
        imageUrl: question.imageUrl || '',
        options,
        randomizedValues,
        actualAnswer,
        explanation,
        solutionSteps: question.solutionSteps || []
    };
};
