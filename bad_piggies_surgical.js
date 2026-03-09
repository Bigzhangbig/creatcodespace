/**
 * Bad Piggies Surgical Rewrite
 * 仅修改抓包已证实的字段（PlayerStatistics, consumables, nonconsumables）
 */

let url = $request.url;
let body = $response.body;

if (!body) $done({});

try {
    let obj = JSON.parse(body);

    // --- 1. 基于数据包 48 (Wallet) 的修改 ---
    if (url.indexOf("/player/wallet") !== -1) {
        obj.consumables = [
            { "id": "SuperGlue", "amount": 999 },
            { "id": "SuperMagnet", "amount": 999 },
            { "id": "TurboCharge", "amount": 999 },
            { "id": "Blueprint", "amount": 999 },
            { "id": "NightVision", "amount": 999 }
        ];
        obj.nonconsumables = [
            { "id": "com.rovio.badpiggies.fullgameunlock" },
            { "id": "com.rovio.badpiggies.fieldofdreams" }
        ];
    }

    // --- 2. 基于数据包 16 (PlayFab Login) 的修改 ---
    if (url.indexOf("LoginWithCustomID") !== -1) {
        if (obj.data && obj.data.InfoResultPayload && obj.data.InfoResultPayload.PlayerStatistics) {
            let stats = obj.data.InfoResultPayload.PlayerStatistics;
            stats.forEach(stat => {
                if (stat.StatisticName === "CakeRaceCupF") {
                    stat.Value = 99999;
                }
                if (stat.StatisticName === "CakeRaceWins") {
                    stat.Value = 999;
                }
            });
        }
    }

    $done({ body: JSON.stringify(obj) });

} catch (e) {
    $done({});
}
