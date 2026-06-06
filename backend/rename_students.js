const mongoose = require('mongoose');
const User = require('./models/User');

mongoose.connect('mongodb://localhost:27017/scimathix').then(async () => {
    await User.updateOne({ name: 'Betty De Alba', role: 'student' }, { $set: { name: 'Maria Santos' } });
    await User.updateOne({ name: 'Christell Faith Cabiguin', role: 'student' }, { $set: { name: 'Juan Dela Cruz' } });
    console.log('Successfully renamed students to Maria Santos and Juan Dela Cruz');
    process.exit(0);
});
