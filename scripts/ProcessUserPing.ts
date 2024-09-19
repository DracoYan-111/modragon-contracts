// import * as fs from 'fs';
// import * as XLSX from 'xlsx';
// import { Parser } from 'json2csv';

// interface PingData {
//     timestamp: string;
//     ping_ping: string;
//     ping_rtt: string;
//     ping_userId: string;
// }

// interface ProcessedData {
//     timestamp: string;
//     ping_ping: number;
//     ping_rtt: number;
//     userId: number;
// }

// const targetUserId = 2411419;
// const processedData: ProcessedData[] = [];

// // 读取Excel文件
// const workbook = XLSX.readFile('2411419用户ping值信息1.xlsx');

// // 获取第一个工作表的名称
// const sheetName = workbook.SheetNames[0];
// const sheet = XLSX.utils.sheet_to_json<PingData>(workbook.Sheets[sheetName]);
// console.log(sheet.length); // heet.length
// if (!sheet || sheet.length === 0) {
//     console.error("Failed to load data from the sheet or the sheet is empty.");
// } else {
//     let i = 0;
//     // 处理数据
//     sheet.forEach((row) => {
//             // 处理可能是单一数据或多个数据的情况
//             const userIds = row.ping_userId.includes(',')
//                 ? row.ping_userId.split(',').map(id => id.trim())
//                 : [row.ping_userId.trim()];

//             const pings = row.ping_ping.includes(',')
//                 ? row.ping_ping.split(',').map(ping => parseInt(ping.trim(), 10))
//                 : [parseInt(row.ping_ping.trim(), 10)];

//             const rtts = row.ping_rtt.includes(',')
//                 ? row.ping_rtt.split(',').map(rtt => parseInt(rtt.trim(), 10))
//                 : [parseInt(row.ping_rtt.trim(), 10)];

// if(userIds.length ==sheet.length ){
//     console.log(userIds.length);
// }

//     });

//     console.log(processedData.length);

//     // // 如果有处理后的数据，导出到CSV
//     // if (processedData.length > 0) {
//     //     const json2csvParser = new Parser();
//     //     const csv = json2csvParser.parse(processedData);
//     //     fs.writeFileSync('processed_data.csv', csv);
//     //     console.log("Data processed and saved to processed_data.csv");
//     // } else {
//     //     console.warn("No data found for the target user.");
//     // }
// }

import * as fs from "fs";
import * as XLSX from "xlsx";
import { Parser } from "json2csv";

interface PingData {
  timestamp: string;
  ping_ping: string;
  ping_rtt: string;
  ping_userId: string;
}

interface ProcessedData {
  timestamp: string;
  ping_ping: number;
  ping_rtt: number;
  userId: number;
}

const targetUserId = 2411419;
const processedData: ProcessedData[] = [];

// 读取Excel文件
const workbook = XLSX.readFile("2411419用户ping值信息1.xlsx");

// 获取第一个工作表的名称
const sheetName = workbook.SheetNames[0];
const sheet = XLSX.utils.sheet_to_json<PingData>(workbook.Sheets[sheetName]);
let i = 0;
console.log(sheet.length);
if (!sheet || sheet.length === 0) {
  console.error("Failed to load data from the sheet or the sheet is empty.");
} else {
  // 处理数据
  sheet.forEach((row) => {
    if (
      typeof row.ping_userId === "string" &&
      typeof row.ping_ping === "string" &&
      typeof row.ping_rtt === "string"
    ) {
      // 处理可能是单一数据或多个数据的情况
      const userIds =  row.ping_userId.split(",").map((id) => id.trim());

      const pings = row.ping_ping.split(",").map((ping) => parseInt(ping.trim(), 10));

      const rtts =  row.ping_rtt.split(",").map((rtt) => parseInt(rtt.trim(), 10));

      // 找到目标用户的索引
      const targetIndex = userIds.indexOf(targetUserId.toString());

      if (targetIndex !== -1) {
        // 保存处理后的数据
        processedData.push({
          timestamp: row.timestamp,
          ping_ping: pings[targetIndex],
          ping_rtt: rtts[targetIndex],
          userId: targetUserId,
        });
      }
    } else {
      processedData.push({
        timestamp: row.timestamp,
        ping_ping:Number(row.ping_ping),
        ping_rtt:Number(row.ping_rtt),
        userId: targetUserId,
      });
    }
  });
  console.log(processedData.length);
  // 如果有处理后的数据，导出到CSV
  if (processedData.length > 0) {
    const json2csvParser = new Parser();
    const csv = json2csvParser.parse(processedData);
    fs.writeFileSync("processed_data.csv", csv);
    console.log("Data processed and saved to processed_data.csv");
  } else {
    console.warn("No data found for the target user.");
  }
}
