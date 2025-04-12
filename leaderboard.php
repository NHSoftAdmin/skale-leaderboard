<?php
// CONFIG
$contractAddress = '0x467aB749Ab104012fF25bab37D69914A703942E4';
//'0x503dc25BE7480E1ae1acB52Df1B4223c5a5368E5';
//'0x6C6035F0A10Ecfe0d70C93D48234A314862FFf20';
$rpcUrl = 'https://testnet.skalenodes.com/v1/lanky-ill-funny-testnet'; // Replace with your SKALE RPC
$ownerAddress = '0xf4A731c9bA087a3C380D4A32f3a115e57d1d3040'; // The wallet that deployed the contract

// getLeaderboard() method signature: getLeaderboard() returns (Entry[])
$methodId = '0x6d763a6e'; // keccak256("getLeaderboard()") = 0x6d763a6e...

// Prepare JSON-RPC payload
$payload = [
    "jsonrpc" => "2.0",
    "method" => "eth_call",
    "params" => [
        [
            "from" => $ownerAddress,
            "to" => $contractAddress,
            "data" => $methodId
        ],
        "latest"
    ],
    "id" => 1
];

// Send the RPC request
$ch = curl_init($rpcUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
curl_close($ch);

$data = json_decode($response, true);
$raw = $data['result'] ?? null;

$entries = [];

if ($raw && strlen($raw) > 2) {
    $raw = substr($raw, 2); // remove 0x
    $count = hexdec(substr($raw, 64, 64)); // offset at 64 — dynamic array length

    for ($i = 0; $i < $count; $i++) {
        $start = 128 + $i * 64 * 2; // each entry is 64 bytes * 2 fields (user + score)
        $user = '0x' . substr($raw, $start + 24, 40);
        $scoreHex = substr($raw, $start + 64, 64);
        $score = hexdec($scoreHex);
        $entries[] = ['user' => $user, 'score' => $score];
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>SKALE Leaderboard</title>
  <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@600&display=swap" rel="stylesheet">
  <style>
    body {
      margin: 0;
      background: #0d0d0d;
      color: #fff;
      font-family: 'Orbitron', sans-serif;
      display: flex;
      justify-content: center;
      align-items: flex-start;
      min-height: 100vh;
      padding: 40px;
    }
    table {
      width: 90%;
      max-width: 1000px;
      border-collapse: collapse;
      box-shadow: 0 0 20px #00f2ff55;
      background: #111;
      border-radius: 12px;
      overflow: hidden;
    }
    th, td {
      padding: 16px;
      text-align: left;
      border-bottom: 1px solid #333;
    }
    th {
      background-color: #0e0e0e;
      color: #00f2ff;
      text-shadow: 0 0 5px #00f2ff88;
    }
    tr:hover {
      background-color: #1a1a1a;
    }
    .rank {
      color: #ffd700;
    }
  </style>
</head>
<body>

  <table>
    <thead>
      <tr>
        <th>#</th>
        <th>Wallet</th>
        <th>Score</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($entries as $i => $entry): ?>
        <tr>
          <td class="rank"><?= $i + 1 ?></td>
		  <td>
			<a href="https://lanky-ill-funny-testnet.explorer.testnet.skalenodes.com/address/<?= $entry['user'] ?>" target="_blank" style="color:#00f2ff; text-decoration:none;">
				<?= $entry['user'] ?>
			</a>
		   </td>	  			
          <td><?= $entry['score'] ?></td>
        </tr>
      <?php endforeach; ?>
    </tbody>
  </table>

</body>
</html>
