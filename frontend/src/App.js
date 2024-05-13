// src/App.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import StudentList from './StudentList';
import AddStudentForm from './AddStudentForm';
import './App.css';

function App() {
  const [students, setStudents] = useState([]);

  useEffect(() => {
    axios.get('http://localhost:3000/students')
      .then(response => {
        setStudents(response.data);
      })
      .catch(error => console.error('Error fetching students:', error));
  }, []);

  const handleAddStudent= (newStudent) => {
    setStudents([...students, newStudent]);
};

  const handleDelete = (id) => {
    axios.delete(`http://localhost:3000/students/${id}`)
      .then(() => {
        setStudents(students.filter(student => student.id !== id));
      })
      .catch(error => console.error('Error deleting students:', error));
  };

  const handleSubmit = (event, formData) => {
    event.preventDefault();
    axios.post('http://localhost:3000/students', formData)
      .then(response => {
        handleAddStudent(formData);
        
      })
      .catch(error => console.error('Error adding students:', error));
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Univesity students list</h1>
      </header>
      <div className="App-body">
        <StudentList students={students} onDelete={handleDelete} />
        <AddStudentForm onSubmit={handleSubmit} />
      </div>
    </div>
  );
}

export default App;
