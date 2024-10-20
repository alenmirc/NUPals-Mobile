// routes/profile.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Notification = require('../models/Notification'); 


// Ensure the uploads directory exists
const uploadDir = 'uploads/';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// Set up multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });

// Register a new user
router.post('/', upload.single('profileImage'), async (req, res) => {
  const { firstName, lastName, email, password, username, age, college, yearLevel, customInterests, categorizedInterests } = req.body;
  const profileImage = req.file ? req.file.path : undefined;

  // Log the incoming request body
  console.log('Incoming Request Body:', req.body);

  // Validate required fields
  const requiredFields = { firstName, lastName, email, password, username, age, college, yearLevel };
  for (const [key, value] of Object.entries(requiredFields)) {
    if (!value) {
      console.error(`${key} is required but was not provided:`, value);
    }
  }

  // Check if any required field is missing
  if (Object.values(requiredFields).some(field => !field)) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  try {
    // Hash password before saving
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser = new User({
      firstName,
      lastName,
      email,
      password: hashedPassword,
      username,
      age,
      college,
      yearLevel,
      profileImage,
      customInterests: customInterests || [],  // Ensure it's set
      categorizedInterests: categorizedInterests || [] // Ensure it's set
    });

    await newUser.save();
    res.status(201).json(newUser);
  } catch (err) {
    console.error('Error during user creation:', err);
    res.status(500).send('Server Error');
  }
});

// Fetch user profile details
router.get('/:userId', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .populate('following followers', 'username')
      .select('-password'); // Exclude password from response

    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }
    
    console.log('Fetched User:', user); // Log the fetched user
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

// Update user profile with image upload
router.post('/:userId/update', upload.single('profileImage'), async (req, res) => {
  const { username, age, college, yearLevel, bio, customInterests, categorizedInterests } = req.body;
  const profileImage = req.file ? req.file.path : undefined;

  try {
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Update user fields, preserving existing values if not provided
    user.username = username || user.username;
    user.age = age || user.age;
    user.college = college || user.college;
    user.yearLevel = yearLevel || user.yearLevel;
    user.bio = bio || user.bio;
    user.profileImage = profileImage || user.profileImage;
    user.customInterests = customInterests || user.customInterests;
    user.categorizedInterests = categorizedInterests || user.categorizedInterests;

    await user.save();
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

// Follow a user
router.post('/:userId/follow', async (req, res) => {
  const { followId } = req.body; // ID of the user being followed

  try {
    // Find the current user (the follower) and the user to follow
    const user = await User.findById(req.params.userId);
    const followUser = await User.findById(followId);

    // Check if both users exist
    if (!user || !followUser) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Check if the current user is already following the user
    if (!user.following.includes(followId)) {
      // Add follow relation
      user.following.push(followId);
      followUser.followers.push(req.params.userId);

      await user.save();
      await followUser.save();

      // Create a follow notification for the followed user
      const notificationMessage = `${user.firstName} ${user.lastName} started following you.`;

      const notification = new Notification({
        type: 'follow',
        senderId: req.params.userId,  // The user who is following
        receiverId: followId,         // The user being followed
        message: notificationMessage
      });

      await notification.save();

      res.json({ msg: 'User followed and notification sent' });
    } else {
      res.status(400).json({ msg: 'Already following' });
    }
  } catch (err) {
    console.error('Server Error:', err);
    res.status(500).send('Server Error');
  }
});

// Unfollow a user
// POST follow a user
router.post('/:userId/follow', async (req, res) => {
  const { userId } = req.params;
  const { followId } = req.body; // This is the ID of the user to follow

  try {
    // Find the user who is following and the user being followed
    const follower = await User.findById(userId);
    const followedUser = await User.findById(followId);

    if (!follower || !followedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if already following
    if (follower.follows.includes(followId)) {
      return res.status(400).json({ message: 'Already following this user' });
    }

    // Update both users
    follower.follows.push(followId);
    followedUser.followers.push(userId);

    await follower.save();
    await followedUser.save();

    // Create a follow notification for the followed user
    const notificationMessage = `${follower.firstName} ${follower.lastName} started following you.`;

    const notification = new Notification({
      type: 'follow',
      senderId: userId,      // The follower
      receiverId: followId,  // The user being followed
      message: notificationMessage
    });

    await notification.save();

    res.status(200).json({ message: 'User followed successfully' });
  } catch (error) {
    console.error('Error following user:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;
