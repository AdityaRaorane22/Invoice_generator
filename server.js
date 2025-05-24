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

// Invoice Counter Schema - Updated to include warranty status
const invoiceCounterSchema = new mongoose.Schema({
  companyName: {
    type: String,
    required: true,
  },
  date: {
    type: String, // Format: DDMMYYYY
    required: true,
  },
  warrantyStatus: {
    type: String, // 'Before' or 'After'
    required: true,
  },
  counter: {
    type: Number,
    default: 0,
  },
  lastUpdated: {
    type: Date,
    default: Date.now,
  }
});

// Compound index to ensure uniqueness per company per date per warranty status
invoiceCounterSchema.index({ companyName: 1, date: 1, warrantyStatus: 1 }, { unique: true });

const InvoiceCounter = mongoose.model('InvoiceCounter', invoiceCounterSchema);

// Invoice Schema
const invoiceSchema = new mongoose.Schema({
  invoiceNumber: {
    type: String,
    required: true,
    unique: true,
  },
  queryId: {
    type: String,
    required: true,
  },
  customerName: {
    type: String,
    required: true,
  },
  customerAddress: {
    type: String,
    required: true,
  },
  companyName: {
    type: String,
    required: true,
  },
  products: [{
    name: {
      type: String,
      required: true,
    },
    price: {
      type: Number,
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
      default: 1,
    }
  }],
  warrantyStatus: {
    type: String,
    enum: ['Before', 'After'],
    required: true,
  },
  subtotal: {
    type: Number,
    required: true,
  },
  taxAmount: {
    type: Number,
    required: true,
  },
  total: {
    type: Number,
    required: true,
  },
  generatedDate: {
    type: Date,
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

const Invoice = mongoose.model('Invoice', invoiceSchema);

// Helper function to format date as DDMMYYYY
function formatDateToDDMMYYYY(date = new Date()) {
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0'); // Month is 0-indexed
  const year = date.getFullYear();
  return `${day}${month}${year}`;
}

// Helper function to get warranty suffix
function getWarrantySuffix(warrantyStatus) {
  return warrantyStatus === 'Before' ? 'bw' : 'aw';
}

// Helper function to get next invoice number with warranty status
async function getNextInvoiceNumber(companyName, warrantyStatus) {
  const today = formatDateToDDMMYYYY();
  
  try {
    // Find or create counter for this company, date, and warranty status
    let counter = await InvoiceCounter.findOne({ 
      companyName: companyName,
      date: today,
      warrantyStatus: warrantyStatus
    });

    if (!counter) {
      // Create new counter for this company, date, and warranty status
      counter = new InvoiceCounter({
        companyName: companyName,
        date: today,
        warrantyStatus: warrantyStatus,
        counter: 1,
      });
    } else {
      // Increment existing counter
      counter.counter += 1;
      counter.lastUpdated = new Date();
    }

    await counter.save();

    // Format invoice number: CompanyName/Date/Counter/WarrantyStatus
    const paddedCounter = counter.counter.toString().padStart(3, '0');
    const warrantySuffix = getWarrantySuffix(warrantyStatus);
    return `${companyName}/${today}/${paddedCounter}/${warrantySuffix}`;

  } catch (error) {
    console.error('Error generating invoice number:', error);
    throw error;
  }
}

// Routes

// Get next invoice number - Updated to include warranty status
app.post('/api/invoices/next-number', async (req, res) => {
  try {
    const { companyName, warrantyStatus } = req.body;
    
    if (!companyName || !warrantyStatus) {
      return res.status(400).json({ error: 'Company name and warranty status are required' });
    }

    const invoiceNumber = await getNextInvoiceNumber(companyName, warrantyStatus);
    
    res.json({ invoiceNumber });
  } catch (error) {
    console.error('Error getting next invoice number:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create new invoice - Updated to use warranty status in invoice number generation
app.post('/api/invoices', async (req, res) => {
  try {
    const {
      queryId,
      customerName,
      customerAddress,
      companyName,
      products,
      warrantyStatus,
      generatedDate,
      subtotal,
      taxAmount,
      total
    } = req.body;

    // Validate required fields
    if (!queryId || !customerName || !customerAddress || !companyName || !products || !warrantyStatus) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Generate invoice number with warranty status
    const invoiceNumber = await getNextInvoiceNumber(companyName, warrantyStatus);

    // Create new invoice
    const invoice = new Invoice({
      invoiceNumber,
      queryId,
      customerName,
      customerAddress,
      companyName,
      products,
      warrantyStatus,
      subtotal,
      taxAmount,
      total,
      generatedDate: new Date(generatedDate),
    });

    await invoice.save();

    res.status(201).json({
      message: 'Invoice created successfully',
      invoice: {
        id: invoice._id,
        invoiceNumber: invoice.invoiceNumber,
        queryId: invoice.queryId,
        customerName: invoice.customerName,
        companyName: invoice.companyName,
        warrantyStatus: invoice.warrantyStatus,
        total: invoice.total,
        createdAt: invoice.createdAt
      }
    });

  } catch (error) {
    console.error('Error creating invoice:', error);
    
    if (error.code === 11000) {
      return res.status(400).json({ error: 'Invoice with this number already exists' });
    }
    
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(3000, () => console.log('Server running on port 3000'));