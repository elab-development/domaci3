// src/FavoritesList.js
import React from 'react';

function StudentList({ students, onDelete }) {
  
  return (
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>First name</th>
          <th>Last name</th>
          <th>Student ID number</th>
          <th>Manage</th>
        </tr>
      </thead>
      <tbody>
        {students.map(student => (
          <tr key={student.id}>
            <td>{student.id}</td>
            <td>{student.first_name}</td>
            <td>{student.last_name}</td>
            <td>{student.student_id}</td>
            <td>
              <button onClick={() => {/* Handle edit */}}>edit</button> |
              <button onClick={() => onDelete(student.id)}>delete</button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}



export default StudentList;
