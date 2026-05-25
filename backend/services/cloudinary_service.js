const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

const storage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'scimathix_lessons',
        allowed_formats: ['jpg', 'png', 'pdf', 'doc', 'docx', 'ppt', 'pptx'],
        resource_type: 'auto'
    },
});

const cloudUpload = multer({ storage: storage });

module.exports = { cloudinary, cloudUpload };
