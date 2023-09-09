const counter = document.querySelector(".counter-number");
async function updateCounter() {
    let response = await fetch(
        "https://nwkahvo7t43jmmmij2tbsxuklu0eqbmf.lambda-url.ap-southeast-2.on.aws/"
    );
    let data = await response.json();
    counter.innerHTML = ` Views: ${data}`;
}
updateCounter();