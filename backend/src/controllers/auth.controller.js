const pool = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

exports.register = async (req, res, next) => {
    try {
        const { email, password, name, dob, gender, category, mobileNo, jeeRank, year, rollNo } = req.body;
        
        // 1. Verify JEE Rank against JEE_RANK_VERIFY
        const [verifyRows] = await pool.query(
            `SELECT * FROM JEE_RANK_VERIFY 
             WHERE JEE_Rank = ? AND Year = ? AND Roll_No = ? AND Name = ? AND Category = ? AND Is_Used = FALSE`,
            [jeeRank, year, rollNo, name, category]
        );
        
        if (verifyRows.length === 0) {
            return res.status(400).json({ success: false, error: 'Invalid or already used JEE details.' });
        }
        
        // 2. Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        
        // 3. Begin transaction
        const connection = await pool.getConnection();
        await connection.beginTransaction();
        
        try {
            // Create Student
            const [studentResult] = await connection.query(
                `INSERT INTO STUDENT (Name, Email, Mobile_No, Date_of_Birth, Gender, Category, JEE_Rank, Year)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                [name, email, mobileNo, dob, gender, category, jeeRank, year]
            );
            const studentId = studentResult.insertId;
            
            // Create User
            await connection.query(
                `INSERT INTO USERS (Email, Password_Hash, Role, Student_ID)
                 VALUES (?, ?, 'Student', ?)`,
                [email, hashedPassword, studentId]
            );
            
            // Mark Verify as used
            await connection.query(
                `UPDATE JEE_RANK_VERIFY SET Is_Used = TRUE WHERE Verify_ID = ?`,
                [verifyRows[0].Verify_ID]
            );
            
            await connection.commit();
            res.status(201).json({ success: true, message: 'Registration successful' });
        } catch (err) {
            await connection.rollback();
            throw err;
        } finally {
            connection.release();
        }
    } catch (err) {
        next(err);
    }
};

exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;
        
        const [users] = await pool.query(`SELECT * FROM USERS WHERE Email = ?`, [email]);
        if (users.length === 0) {
            return res.status(400).json({ success: false, error: 'Invalid credentials' });
        }
        
        const user = users[0];
        const isMatch = await bcrypt.compare(password, user.Password_Hash);
        
        if (!isMatch) {
            return res.status(400).json({ success: false, error: 'Invalid credentials' });
        }
        
        const payload = {
            id: user.User_ID,
            role: user.Role,
            studentId: user.Student_ID,
            instituteId: user.Institute_ID
        };
        
        const token = jwt.sign(payload, process.env.JWT_SECRET || 'supersecretjwtkey', { expiresIn: '1d' });
        
        res.json({ success: true, token, user: payload });
    } catch (err) {
        next(err);
    }
};
