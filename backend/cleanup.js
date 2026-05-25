const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI).then(async () => {
    const res = await mongoose.connection.collection('users').deleteMany({ email: { $in: ['student@test.com', 'teacher@test.com', 'admin@test.com'] } });
    console.log('Deleted', res.deletedCount);
    process.exit();
});
