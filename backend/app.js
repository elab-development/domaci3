const express = require('express');
const bodyParser = require('body-parser');
const mysql = require('mysql2');
const axios = require('axios');
const cors = require('cors');

const app = express();
const port = 3000;
app.use(cors());
app.use(bodyParser.json());

// MySQL connection setup
const connection = mysql.createConnection({
  host: 'mysql-server', //ovde staviti naziv mysql servera u mrezi
  user: 'student', 
  password: 'student',
  database: 'university'
});

connection.connect(err => {
    if (err) throw err;
    console.log('Connected to the database.');
  
    const createTableSql = `
      CREATE TABLE IF NOT EXISTS students (
        id INT AUTO_INCREMENT PRIMARY KEY,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        student_id VARCHAR(100) NOT NULL
      )
    `;
  
    connection.query(createTableSql, (err, result) => {
      if (err) throw err;
      console.log("Table 'students' is ready.");
    });
  });


// Endpoint za ptistup svim studentima
app.get('/students', (req, res) => {
  connection.query('SELECT * FROM students', (error, results) => {
    if (error) throw error;
    res.json(results);
  });
});

// Endpoint za dodavanje jednog studenta
app.post('/students', (req, res) => {
  const { first_name, last_name, student_id } = req.body;
  const query = 'INSERT INTO students (first_name, last_name, student_id) VALUES (?, ?, ?)';
  connection.query(query, [first_name, last_name, student_id], (error, results) => {
    if (error) throw error;
    res.status(201).send(`Student dodat u bazu sa ID-em: ${results.insertId}`);
  });
});

// Endpoint za brisanje jednog studenta
app.delete('/students/:id', (req, res) => {
  const { id } = req.params;
  const query = 'DELETE FROM students WHERE id = ?';
  connection.query(query, [id], (error, results) => {
    if (error) throw error;
    res.send(`Student sa ID-em ${id} obrisan.`);
  });
});

// Endpoint to update a favorite
app.put('/students/:id', (req, res) => {
  const { id } = req.params;
  const { first_name, last_name, student_id } = req.body;
  const query = 'UPDATE students SET first_name = ?, last_name = ?, student_id = ? WHERE id = ?';
  connection.query(query, [first_name, last_name, student_id, id], (error, results) => {
    if (error) throw error;
    res.send(`Student sa ID-em ${id} azuriran.`);
  });
});



app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
