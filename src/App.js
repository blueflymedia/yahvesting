
import CountdownTimer from "./CountdownTimer";
import React from "react";


export default function App() {
  const countDownDate = new Date("November 26, 2023 13:02:35").getTime();
  console.log('countdown date:',countDownDate);
  const THREE_DAYS_IN_MS = 3 * 24 * 60 * 60 * 1000;
  const SEVEN_DAYS_IN_MS = 7 * 24 * 60 * 60 * 1000;
  const now = new Date().getTime();
  const distance = countDownDate - now; 

  const launchDate = now + distance;
  function decimalRound(bal, decimals) {
    if (!decimals) decimals = 2;
    return Number.parseFloat(bal).toFixed(decimals);
  }

return (
  <>
    <main className="container-fluid text-center">
      <div className="container mx-auto">
        <div className="row pt-2">
        <div className="d-flex justify-content-center ">
          <div className="col-12">
            <h3>Wormies.app</h3>
            <h2><CountdownTimer targetDate={launchDate} /></h2>
          </div>
        </div>
            </div>
          </div>
          
          </main>
    </>
  );
}
