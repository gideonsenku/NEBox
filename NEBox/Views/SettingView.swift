//
//  SettingView.swift
//  BoxJs
//
//  Created by Senku on 7/5/24.
//

import SwiftUI
import MarkdownUI

struct SettingView: View {
    let markdownString = """
      #### 获取Cookie以及脚本配置请查看[脚本注释](https://raw.githubusercontent.com/NobyDa/Script/master/JD-DailyBonus/JD_DailyBonus.js)

      #### 如需修改Cookie列表请严格按照[JSON格式](https://www.bejson.com/json/format)修改

      #### 建议通过脚本获取Cookie

        

      ### 签到相关教程
      - [x] Write the press release
      
      ```javascript
      const name = "hello"
      ```
      """
    var body: some View {
        Markdown(markdownString)
            .markdownTheme(.gitHub)
    }
}

#Preview {
    SettingView()
}
