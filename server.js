const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect('mongodb://localhost:27017/invoice');

const User = mongoose.model('User', {
  fullName: String,
  dob: String,
  gender: String,
  address: String,
  mobile: String,
  password: String,
});

// Define Chat model for storing chat messages
const Chat = mongoose.model('Chat', {
  mobile: String,
  messages: [{
    text: String,
    isUser: Boolean,
    timestamp: Date
  }],
  createdAt: { type: Date, default: Date.now }
});

app.post('/signup', async (req, res) => {
  const user = new User(req.body);
  await user.save();
  res.send({ message: 'Registered successfully' });
});

app.post('/login', async (req, res) => {
  const { mobile, password } = req.body;
  const user = await User.findOne({ mobile, password });
  if (user) {
    res.send({ success: true });
  } else {
    res.send({ success: false, message: 'Invalid credentials' });
  }
});

// 🔥 This is the new GET route for fetching user data by mobile
app.get('/user', async (req, res) => {
  const { mobile } = req.query;
  try {
    const user = await User.findOne({ mobile });
    if (user) {
      res.json(user);
    } else {
      res.status(404).send({ message: 'User not found' });
    }
  } catch (err) {
    res.status(500).send({ message: 'Server error' });
  }
});

// Save chat messages to database
app.post('/save-chat', async (req, res) => {
  try {
    console.log('Received save-chat request:', req.body);
    
    const { mobile, userMessage, aiMessage } = req.body;
    
    // Validate required fields
    if (!mobile || !userMessage || !aiMessage) {
      return res.status(400).json({ 
        success: false, 
        message: 'Missing required fields' 
      });
    }
    
    const chatEntry = new Chat({
      mobile: mobile,
      messages: [userMessage, aiMessage],
      createdAt: new Date()
    });
    
    console.log('Saving chat entry:', chatEntry);
    
    // Save using Mongoose
    const result = await chatEntry.save();
    
    console.log('Chat saved successfully with ID:', result._id);
    
    res.json({ 
      success: true, 
      message: 'Chat saved successfully',
      id: result._id 
    });
  } catch (error) {
    console.error('Error saving chat:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to save chat',
      error: error.message 
    });
  }
});

// Get chat history for a specific mobile number
app.get('/chat-history/:mobile', async (req, res) => {
  try {
    const mobile = req.params.mobile;
    
    // Find all chat entries for this mobile number using Mongoose
    const chatHistory = await Chat.find({ mobile: mobile })
      .sort({ createdAt: 1 });
    
    // Flatten the messages array to get all messages in chronological order
    const allMessages = [];
    chatHistory.forEach(entry => {
      if (entry.messages && Array.isArray(entry.messages)) {
        allMessages.push(...entry.messages);
      }
    });
    
    res.json({ 
      success: true, 
      messages: allMessages 
    });
  } catch (error) {
    console.error('Error fetching chat history:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch chat history' 
    });
  }
});

// Optional: Get all chat data for admin purposes
app.get('/admin/all-chats', async (req, res) => {
  try {
    const allChats = await Chat.find({})
      .sort({ createdAt: -1 });
    
    res.json({ 
      success: true, 
      chats: allChats 
    });
  } catch (error) {
    console.error('Error fetching all chats:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch chats' 
    });
  }
});

// Optional: Delete chat history for a specific mobile number
app.delete('/chat-history/:mobile', async (req, res) => {
  try {
    const mobile = req.params.mobile;
    
    const result = await Chat.deleteMany({ mobile: mobile });
    
    res.json({ 
      success: true, 
      message: `Deleted ${result.deletedCount} chat entries` 
    });
  } catch (error) {
    console.error('Error deleting chat history:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to delete chat history' 
    });
  }
});

app.listen(3000, () => console.log('Server running on port 3000'));