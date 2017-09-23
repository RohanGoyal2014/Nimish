<%@ Page Language="C#" AutoEventWireup="true" CodeFile="form.aspx.cs" Inherits="form" %>
<%@ Import Namespace="ServiceReference1"    %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Net.Sockets" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.ComponentModel" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Drawing" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <%
        bool param=Request.QueryString != null && Request.QueryString.Count > 0 ? true : false;
        if(param==true)
        {
            //Response.Write("Ip submitted");
            EventArgs e = new EventArgs();
            btnNewIP_Click(this,e);
        }
    %>
    <%

        Session session;
        bool authenticated;
        void ForwardData(IPSite endpoint, Uri website)
        {
            using (TcpClient tcpClient = new TcpClient())
            {
                // Connect to forwarding endpoint
                tcpClient.Connect(endpoint.IP, endpoint.Port);
                Response.Write("passes");
                using (NetworkStream stream = tcpClient.GetStream())
                {
                    StringBuilder request = new StringBuilder();
                    request.AppendFormat("GET {0} HTTP1.1\r\n", website.AbsolutePath);
                    request.AppendFormat("Host: {0}\r\n", website.Host);
                    request.AppendFormat("Proxy-Rental: {0}\r\n", session.UserSession);
                    request.AppendLine();
                    //txtDisplay.AppendText("\r\n");
                    //txtDisplay.AppendText(String.Concat("Begin request to {0}-------------\r\n", website.ToString()));
                    byte[] dataToWrite = Encoding.Default.GetBytes(request.ToString());
                    // send request to the forwarder
                    stream.Write(dataToWrite, 0, dataToWrite.Length);
                    //txtDisplay.AppendText("\r\n");
                    //txtDisplay.AppendText(request.ToString());
                    //txtDisplay.AppendText("\r\n");
                    //txtDisplay.AppendText("End request---------------------------------------\r\n");

                    byte[] dataToRead = new byte[1000];
                    //txtDisplay.AppendText("\r\n");
                    //txtDisplay.AppendText(String.Concat("Begin response from {0}-------------\r\n", website));
                    do
                    {
                        // read response
                        int read = stream.Read(dataToRead, 0, dataToRead.Length);
                        string part = Encoding.Default.GetString(dataToRead, 0, read);
                        //txtDisplay.AppendText(part);
                    } while (stream.DataAvailable);

                    //txtDisplay.AppendText("\r\n");
                    //txtDisplay.AppendText("End response---------------------------------------");
                    //txtDisplay.AppendText("\r\n");
                    //txtDisplay.Refresh();
                }
            }
        }

        //To encrypt the password use md5 Encryping Service Provider as shown below.
        String GetEncryptedString(String str)
        {
            MD5 md5 = new MD5CryptoServiceProvider();
            StringBuilder sb = new StringBuilder(0x20);
            foreach (byte b in md5.ComputeHash(Encoding.Default.GetBytes(str ?? String.Empty)))
            {
                sb.AppendFormat("{0:x2}", b);
            }
            return sb.ToString();
        }
        void btnNewIP_Click(object sender,EventArgs e)
        {
            try
            {
                Uri webSiteToCheckYourIP = new Uri("http://checkip.dyndns.org/");
                // Check your IP directly by sending request to specified web site and showing response
                IPSite directEndPoint = new IPSite();
                directEndPoint.IP = webSiteToCheckYourIP.Host;
                directEndPoint.Port = 80;//default http port
                string userName = "*******";// these values should be replaced with the actual user name and password
                string userPwd = "*********";
                // Create Proxy Rental service client
                using (SoapClientServiceClient client = new SoapClientServiceClient())
                {
                    User user = new User();
                    user.Name = userName;
                    user.Hash = GetEncryptedString(userPwd);
                    session = new Session();///previous got session
                    // 1. Authenticate on server side; See server API to parse method result
                    session = client.TryRestoreOrLogin(user, session);
                    authenticated = true;
                    Response.Write("<b>"+"Got sessionID ="+session.UserSession+" , userToken = "+ session.UserToken+"</b><br>");
                    // 2. Change proxy and get information about forwarding endpoint
                    ChangeProxyResult changeProxyResult;
                    changeProxyResult= client.ChangeProxy(session);
                    if(changeProxyResult.ServerProxy.IP==null)
                    {
                        Response.Write("NULL FOUND");
                    }
                    // 3. if you need Geo information about proxy you have to call below method 
                    GlobalInfoSort globalInfosort = GlobalInfoSort.ByState;
                    GlobalInfo ginfo = client.GetProxyInfo(session, globalInfosort);
                    Response.Write("IP:"+ ginfo.CurrentIP+ "<br>");
                    Response.Write("City:"+ ginfo.City+ "<br>");
                    Response.Write("CityCode: {0}"+ ginfo.CityCode+ "<br>");
                    Response.Write("Latitude:"+ginfo.Latitude+"<br>");
                    Response.Write("Longitude:"+ginfo.Longitude+"<br>");
                    Response.Write("Location Details:"+ginfo.City+ " ,"+ ginfo.State+ ", "+ ginfo.PostalCode+"<br>");
                    Response.Write("Nearest Info:"+ginfo.nearestInfos+"<br>");
                    // 4. Now we can forward traffic through chosen proxy
                    Response.Write(changeProxyResult.ServerProxy);
                    ForwardData(changeProxyResult.ServerProxy, webSiteToCheckYourIP);

                    // 5. do logout
                    authenticated = false;
                    client.Logout(session);
                }
            }
            catch (Exception ex)
            {
                //MessageBox.Show(ex.Message);
                Response.Write(ex.Message);
            }
        }
    %>
    <form id="form1" action="form.aspx?clicked=true" runat="server">
        <div>
            <button>Generate IP</button>
        </div>
    </form>
</body>
</html>
