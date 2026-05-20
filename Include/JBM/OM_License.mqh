//+------------------------------------------------------------------+
//|  OM_License.mqh — License Validation (Phase 3)                   |
//|  Placeholder — will ping license server via WebRequest           |
//+------------------------------------------------------------------+
#ifndef OM_LICENSE_MQH
#define OM_LICENSE_MQH

// TODO Phase 3: implement HTTP license check
// Format: JBM-XXXX-XXXX-XXXX-XXXX
// Binding: MT5 account number (max 2 accounts per key)
// Grace:   24h offline mode if server unreachable

bool ValidateLicense(string key)
  {
   // Phase 1 & 2: always return true (no license check yet)
   return true;

   // Phase 3 implementation:
   // string url = "https://api.jbmtrading.com/v1/verify";
   // string body = "key=" + key + "&account=" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   // char   post[], result[];
   // StringToCharArray(body, post);
   // int res = WebRequest("POST", url, "Content-Type: application/x-www-form-urlencoded\r\n",
   //                      5000, post, result, "");
   // if(res == 200) {
   //    string response = CharArrayToString(result);
   //    return StringFind(response, "\"valid\":true") >= 0;
   // }
   // return false;
  }

#endif // OM_LICENSE_MQH
