const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

const seedUsers = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected for Seeding');

        const users = [
            {
                name: 'Test Student',
                email: 'student@test.com',
                password: 'password123',
                role: 'student',
            },
            {
                name: 'Test Teacher',
                email: 'teacher@test.com',
                password: 'password123',
                role: 'teacher',
            },
            {
                name: 'Test Admin',
                email: 'admin@test.com',
                password: 'password123',
                role: 'admin',
            }
        ];

        // Only insert if they don't already exist
        for (const user of users) {
            const exists = await User.findOne({ email: user.email });
            if (!exists) {
                await User.create(user);
                console.log(`Created ${user.role} account: ${user.email}`);
            } else {
                console.log(`Account ${user.email} already exists`);
            }
        }

        console.log('Seeding complete!');
        process.exit();
    } catch (error) {
        console.error('Seeding error:', error);
        process.exit(1);
    }
};

seedUsers();
