interface PlayerInfo {
    sceneName: string;
    userId: string;
    ping: number;
    rtt: number;
  }
  
  class LogProcessor {
    handlePingMessage(message: string): PlayerInfo | null {
      // 使用正则表达式匹配并提取P_PING开头和#P12结尾之间的内容
      const match = message.match(/P_PING: \["(.*?)","(.*?)",(.*?),(.*?)\] #P12/);
      if (match) {
        const playerInfo: PlayerInfo = {
          sceneName: match[1],
          userId: match[2],
          ping: Number(match[3]),
          rtt: Number(match[4])
        };
        console.log(playerInfo);
        return playerInfo;
      }
      console.log("No match found.");
      return null;
    }
  }
  
  const logs = ["2024.08.06-15.21.23 MWTS: Info P_PING: [\"dragon\",\"2411082\",25,133] #P12"];
  
  // 创建LogProcessor实例
  const logProcessor = new LogProcessor();
  
  // 处理第一个日志条目
  const playerInfo = logProcessor.handlePingMessage(logs[0]);
  
  // 你也可以直接使用 playerInfo 变量进行其他处理