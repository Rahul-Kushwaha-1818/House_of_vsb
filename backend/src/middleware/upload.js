const multer = require('multer');
const path = require('path');
const fs = require('fs');

const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    let ext = path.extname(file.originalname || '').toLowerCase();
    if (!ext && file.mimetype) {
      if (file.mimetype === 'image/jpeg') ext = '.jpg';
      else if (file.mimetype === 'image/png') ext = '.png';
      else if (file.mimetype === 'image/webp') ext = '.webp';
      else if (file.mimetype === 'image/gif') ext = '.gif';
      else ext = '.jpg';
    }
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `auction-${uniqueSuffix}${ext || '.jpg'}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowedExtensions = /\.(jpeg|jpg|png|webp|gif|bmp|heic|svg)$/i;
  const isImageMime = file.mimetype && (file.mimetype.startsWith('image/') || file.mimetype === 'application/octet-stream');
  const hasImageExt = allowedExtensions.test(file.originalname || '');

  if (isImageMime || hasImageExt) {
    return cb(null, true);
  }
  cb(new Error('Only image files (jpeg, jpg, png, webp, gif) are allowed'));
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
});

module.exports = upload;
