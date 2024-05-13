// src/AddFavoriteForm.js
import React, { useState } from 'react';

function AddStudentForm({ onSubmit }) {
  const [formData, setFormData] = useState({
    first_name: '',
    last_name: '',
    student_id: ''
  });


  const handleChange = (event) => {
    const { name, value } = event.target;
    setFormData(prevFormData => ({
      ...prevFormData,
      [name]: value
    }));
  };

  const localHandleSubmit = (event) => {
    event.preventDefault();
    onSubmit(event, formData);
  };

  return (
    <form onSubmit={localHandleSubmit}>
      <label>
        ime<br/>
        <input name="first_name" value={formData.first_name} onChange={handleChange} />
      </label><br/>
      <label>
        prezime<br/>
        <input name="last_name" value={formData.last_name} onChange={handleChange} />
      </label><br/>
      <label>
      br_indeksa<br/>
        <input name="student_id" value={formData.student_id} onChange={handleChange} />
      </label><br/>
      <button type="submit">ADD</button>
    </form>
  );
}



export default AddStudentForm;
