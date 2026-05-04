const pool = require('../config/db');

exports.getInstitutes = async (req, res, next) => {
    try {
        const [institutes] = await pool.query('SELECT * FROM INSTITUTE ORDER BY Institute_Name');
        res.json({ success: true, data: institutes });
    } catch (err) {
        next(err);
    }
};

exports.getPrograms = async (req, res, next) => {
    try {
        const { instituteId } = req.query;
        let query = 'SELECT P.*, I.Institute_Name FROM PROGRAM P JOIN INSTITUTE I ON P.Institute_ID = I.Institute_ID';
        const queryParams = [];
        
        if (instituteId) {
            query += ' WHERE P.Institute_ID = ?';
            queryParams.push(instituteId);
        }
        
        query += ' ORDER BY I.Institute_Name, P.Program_Name';
        
        const [programs] = await pool.query(query, queryParams);
        res.json({ success: true, data: programs });
    } catch (err) {
        next(err);
    }
};

exports.getSeatMatrix = async (req, res, next) => {
    try {
        const { programId } = req.params;
        const [matrix] = await pool.query(
            'SELECT * FROM SEAT_MATRIX WHERE Program_ID = ? ORDER BY Category',
            [programId]
        );
        res.json({ success: true, data: matrix });
    } catch (err) {
        next(err);
    }
};
