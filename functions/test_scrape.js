const axios = require("axios");

async function testScrape() {
    try {
        const url = "https://api.namthong.com/api/gold_price";
        const response = await axios.get(url, {
            headers: {
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0'
            }
        });

        const data = response.data;
        console.log("API Response:");
        console.log(JSON.stringify(data, null, 2));

        let buyPrice = 0;
        let sellPrice = 0;

        const stringData = JSON.stringify(data);
        const buyMatches = stringData.match(/"buy":\s*(\d{5})/gi);
        const sellMatches = stringData.match(/"sell":\s*(\d{5})/gi);

        if (buyMatches && sellMatches) {
            const buys = buyMatches.map(m => parseInt(m.replace(/[^\d]/g, ''), 10));
            const sells = sellMatches.map(m => parseInt(m.replace(/[^\d]/g, ''), 10));

            buyPrice = buys[0];
            sellPrice = sells[0];
            console.log(`Parsed -> Buy: ${buyPrice}, Sell: ${sellPrice}`);
        } else {
            console.error("Failed to find price format locally.");
        }
    } catch (error) {
        console.error("Request failed!");
        if (error.response) {
            console.error(error.response.status, error.response.data);
        } else {
            console.error(error.message);
        }
    }
}

testScrape();
