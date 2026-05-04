const pool = require('../config/db');

exports.getChoices = async (req, res, next) => {
    try {
        const studentId = req.user.studentId;
        const [choices] = await pool.query(
            `SELECT C.*, P.Program_Name, I.Institute_Name 
             FROM CHOICE C
             JOIN PROGRAM P ON C.Program_ID = P.Program_ID
             JOIN INSTITUTE I ON P.Institute_ID = I.Institute_ID
             WHERE C.Student_ID = ? AND C.Status = 'Active'
             ORDER BY C.Preference_Order`,
            [studentId]
        );
        res.json({ success: true, data: choices });
    } catch (err) {
        next(err);
    }
};

exports.addChoices = async (req, res, next) => {
    try {
        const studentId = req.user.studentId;
        const { programIds } = req.body; 
        
        if (!Array.isArray(programIds) || programIds.length === 0) {
            return res.status(400).json({ success: false, error: 'Please provide an array of programIds' });
        }
        
        const connection = await pool.getConnection();
        await connection.beginTransaction();
        
        try {
            const [maxPrefRows] = await connection.query(
                `SELECT COALESCE(MAX(Preference_Order), 0) as maxPref FROM CHOICE WHERE Student_ID = ?`,
                [studentId]
            );
            let currentMax = maxPrefRows[0].maxPref;
            
            for (const programId of programIds) {
                currentMax++;
                await connection.query(
                    `INSERT INTO CHOICE (Student_ID, Program_ID, Preference_Order) VALUES (?, ?, ?)`,
                    [studentId, programId, currentMax]
                );
            }
            
            await connection.commit();
            res.status(201).json({ success: true, message: 'Choices added successfully' });
        } catch (err) {
            await connection.rollback();
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(400).json({ success: false, error: 'One or more choices already exist' });
            }
            throw err;
        } finally {
            connection.release();
        }
    } catch (err) {
        next(err);
    }
};

exports.deleteChoice = async (req, res, next) => {
    try {
        const studentId = req.user.studentId;
        const { choiceId } = req.params;
        
        const connection = await pool.getConnection();
        await connection.beginTransaction();
        
        try {
            const [result] = await connection.query(
                `DELETE FROM CHOICE WHERE Choice_ID = ? AND Student_ID = ?`,
                [choiceId, studentId]
            );
            
            if (result.affectedRows === 0) {
                await connection.rollback();
                return res.status(404).json({ success: false, error: 'Choice not found or unauthorized' });
            }
            
            await connection.query(`SET @rank = 0`);
            await connection.query(
                `UPDATE CHOICE SET Preference_Order = (@rank := @rank + 1) WHERE Student_ID = ? ORDER BY Preference_Order`,
                [studentId]
            );
            
            await connection.commit();
            res.json({ success: true, message: 'Choice removed and preferences reordered' });
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

exports.reorderChoices = async (req, res, next) => {
    try {
         const studentId = req.user.studentId;
         const { orderedChoiceIds } = req.body;
         
         if (!Array.isArray(orderedChoiceIds) || orderedChoiceIds.length === 0) {
             return res.status(400).json({ success: false, error: 'Provide orderedChoiceIds array' });
         }
         
         const connection = await pool.getConnection();
         await connection.beginTransaction();
         
         try {
             for (let i = 0; i < orderedChoiceIds.length; i++) {
                 await connection.query(
                     `UPDATE CHOICE SET Preference_Order = ? WHERE Choice_ID = ? AND Student_ID = ?`,
                     [i + 1, orderedChoiceIds[i], studentId]
                 );
             }
             await connection.commit();
             res.json({ success: true, message: 'Choices reordered successfully' });
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
