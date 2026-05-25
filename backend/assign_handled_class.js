const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/User');
const Section = require('./models/Section');
const Subject = require('./models/Subject');
const Level = require('./models/Level');

dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/scimathix';

async function updateTeacher() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('Connected to MongoDB');

        const teacher = await User.findOne({ role: 'teacher' });
        if (!teacher) {
            console.log("No teacher found.");
            process.exit(0);
        }

        let level = await Level.findOne();
        if (!level) {
            level = await Level.create({ name: 'Grade 10', description: 'Tenth Grade' });
            console.log("Created Level");
        }

        let section = await Section.findOne();
        if (!section) {
            section = await Section.create({ name: 'Section A', level: level._id });
            console.log("Created Section");
        }

        let subject = await Subject.findOne();
        if (!subject) {
            subject = await Subject.create({ name: 'Mathematics', code: 'MATH-101' });
            console.log("Created Subject");
        }

        // Check if it already has this handled class
        const hasClass = teacher.handledClasses.some(hc => 
            hc.section.toString() === section._id.toString() && 
            hc.subject.toString() === subject._id.toString()
        );

        if (!hasClass) {
            teacher.handledClasses.push({
                section: section._id,
                subject: subject._id
            });
            await teacher.save();
            console.log(`Assigned Section ${section.name} and Subject ${subject.name} to Teacher ${teacher.name}`);
        } else {
            console.log('Teacher already has this handled class assigned.');
        }

    } catch (err) {
        console.error(err);
    } finally {
        mongoose.disconnect();
        process.exit(0);
    }
}

updateTeacher();
