const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const userSchema = new Schema({
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  username: { type: String, required: true },
  age: { type: Number, default: null },
  college: { type: String, default: '' },
  yearLevel: { type: String, default: '' },
  bio: { type: String, default: '' },
  profileImage: { type: String, default: '' },
  customInterests: { type: [String], default: [] }, // New field for custom interests
  categorizedInterests: { type: [String], default: [] }, // New field for categorized interests
  role: { type: String, default: 'student' },
  following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }]
}, { timestamps: true });

const User = mongoose.models.User || mongoose.model('User', userSchema);

module.exports = User;