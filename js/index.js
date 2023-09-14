const counter = document.querySelector(".counter-number");
async function updateCounter() {
    let response = await fetch(
        "https://45382oh0a9.execute-api.ap-southeast-2.amazonaws.com/"
    );
    let data = await response.json();
    counter.innerHTML = ` Views: ${data}`;
}
updateCounter();