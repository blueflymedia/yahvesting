import React from 'react';

const DateTimeDisplay = ({ value, type, isDanger }) => {
  return (
    <span className={isDanger ? 'countdown danger' : 'countdown'}>
      {value}{type}
    </span>
  );
};

export default DateTimeDisplay;