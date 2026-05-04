const pool = require('../config/db');

exports.getProfile = async (req, res, next) => {
    try {
        const studentId = req.user.studentId;
        
        const [students] = await pool.query(
            `SELECT Student_ID, Name, Email, Mobile_No, Date_of_Birth, Gender, Category, JEE_Rank, Year 
             FROM STUDENT WHERE Student_ID = ?`,
            [studentId]
        );
        
        if (students.length === 0) {
            return res.status(404).json({ success: false, error: 'Student not found' });
        }
        
        res.json({ success: true, data: students[0] });
    } catch (err) {
        next(err);
    }
};
