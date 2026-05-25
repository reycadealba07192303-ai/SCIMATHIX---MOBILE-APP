const express = require('express');
const router = express.Router();
const { protect, adminOnly } = require('../middleware/auth_middleware');
const {
    getAllUsers,
    createUser,
    updateUser,
    deleteUser
} = require('../controllers/user_controller');

router.route('/')
    .get(protect, adminOnly, getAllUsers)
    .post(protect, adminOnly, createUser);

router.route('/:id')
    .put(protect, adminOnly, updateUser)
    .delete(protect, adminOnly, deleteUser);

module.exports = router;
