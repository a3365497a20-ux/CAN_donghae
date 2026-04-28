<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" import="java.sql.*,java.util.*" %>
<%
    String loginUser=(String)session.getAttribute("loginUser");
    String loginName=(String)session.getAttribute("loginName");
    if(loginUser==null){response.sendRedirect("/CAN/campuslogin.jsp");return;}
    if(!"admin".equals(session.getAttribute("loginRole"))){response.sendRedirect("/CAN/campuslogin.jsp");return;}

    final String DBURL="jdbc:mysql://localhost:3306/campusnav?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8&allowPublicKeyRetrieval=true";

    String okMsg="",errMsg="";
    String filterType=request.getParameter("type");if(filterType==null)filterType="";
    String filterStatus=request.getParameter("status");if(filterStatus==null)filterStatus="";

    // ── POST 처리 (예약 취소) ──
    if("POST".equals(request.getMethod())){
        request.setCharacterEncoding("UTF-8");
        String act=request.getParameter("act");
        if("cancelReserve".equals(act)){
            String rid=request.getParameter("reserveId");
            String type=request.getParameter("type");if(type==null)type="";
            try{
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection c=DriverManager.getConnection(DBURL,"root","1234");
                int n=0;
                if("room".equals(type)){
                    PreparedStatement ps=c.prepareStatement("UPDATE room_reservations SET status='취소' WHERE reserve_id=?");
                    ps.setString(1,rid);n=ps.executeUpdate();ps.close();
                } else {
                    PreparedStatement ps=c.prepareStatement("UPDATE reservations SET status='취소' WHERE reserve_id=?");
                    ps.setString(1,rid);n=ps.executeUpdate();ps.close();
                }
                c.close();
                okMsg=n>0?"예약 #"+rid+" 취소 완료":"해당 예약을 찾을 수 없습니다.";
            }catch(Exception e){errMsg="취소 오류: "+e.getMessage();}
        }
    }

    // ── 예약 조회 ──
    List<Map<String,String>> allReserves=new ArrayList<>();
    try{
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn=DriverManager.getConnection(DBURL,"root","1234");

        // 자산 예약 조회
        String sql="SELECT r.reserve_id,r.user_id,u.user_name,r.asset_no,'자산' AS room_type,IFNULL(a.item_name,'자산') AS item_name,r.reserve_date,r.start_time,r.end_time,r.status,r.purpose,'asset' AS reserve_type ";
        sql+="FROM reservations r LEFT JOIN assets a ON r.asset_no=a.asset_no LEFT JOIN users u ON r.user_id=u.user_id ";
        sql+="WHERE 1=1";
        if(!filterStatus.isEmpty()) sql+=" AND r.status='"+filterStatus+"'";
        sql+=" UNION ALL SELECT rr.reserve_id,rr.user_id,u.user_name,CAST(rr.room_id AS CHAR),rm.room_type,rm.room_name,rr.reserve_date,rr.start_time,rr.end_time,rr.status,rr.purpose,'room' ";
        sql+="FROM room_reservations rr LEFT JOIN rooms rm ON rr.room_id=rm.room_id LEFT JOIN users u ON rr.user_id=u.user_id ";
        sql+="WHERE 1=1";
        if(!filterType.isEmpty()) sql+=" AND rm.room_type='"+filterType+"'";
        if(!filterStatus.isEmpty()) sql+=" AND rr.status='"+filterStatus+"'";
        sql+=" ORDER BY reserve_date DESC, start_time DESC";

        ResultSet rs=conn.createStatement().executeQuery(sql);
        while(rs.next()){
            Map<String,String> m=new LinkedHashMap<>();
            m.put("id",rs.getString("reserve_id")!=null?rs.getString("reserve_id"):"");
            m.put("uid",rs.getString("user_id")!=null?rs.getString("user_id"):"");
            m.put("uname",rs.getString("user_name")!=null?rs.getString("user_name"):rs.getString("user_id"));
            m.put("name",rs.getString("item_name")!=null?rs.getString("item_name"):"");
            m.put("type",rs.getString("room_type")!=null?rs.getString("room_type"):"");
            m.put("date",rs.getString("reserve_date")!=null?rs.getString("reserve_date"):"");
            m.put("start",rs.getString("start_time")!=null?rs.getString("start_time"):"");
            m.put("end",rs.getString("end_time")!=null?rs.getString("end_time"):"");
            m.put("status",rs.getString("status")!=null?rs.getString("status"):"");
            m.put("purpose",rs.getString("purpose")!=null?rs.getString("purpose"):"");
            m.put("rtype",rs.getString("reserve_type")!=null?rs.getString("reserve_type"):"");
            allReserves.add(m);
        }
        rs.close();conn.close();
    }catch(Exception e){errMsg+="조회오류: "+e.getMessage();}
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ICT CAN — 예약 관리</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,700;9..40,800&family=DM+Mono:wght@400;500&family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/CAN/css/common.css">
<style>
.filter-tabs{display:flex;gap:8px;margin-bottom:20px;flex-wrap:wrap;}
.filter-tab{padding:8px 16px;border-radius:20px;background:var(--bg);border:1px solid var(--line);color:var(--txt2);text-decoration:none;cursor:pointer;font-size:13px;transition:all .2s;}
.filter-tab:hover,.filter-tab.active{background:var(--blue);border-color:var(--blue);color:white;font-weight:700;}
</style>
</head>
<body>
<div class="topnav">
  <a href="/CAN/main_admin.jsp" class="logo">
    <span class="logo-dot"><img src="/CAN/images/logo.png" alt="ICT"></span>
    ICT <em>CAN</em>
  </a>
  <div class="nav-right">
    <span style="font-family:var(--mono);font-size:13px;color:var(--txt2)"><i class="bi bi-person-circle"></i> <%= loginName %></span>
    <span class="role-chip">운영관리자</span>
    <a href="/CAN/main_admin.jsp" class="chip"><i class="bi bi-house"></i> 대시보드</a>
    <form action="/CAN/logout" method="post" style="margin:0">
      <button type="submit" class="chip"><i class="bi bi-box-arrow-right"></i> 로그아웃</button>
    </form>
  </div>
  <button class="nav-hamburger" onclick="toggleMenu()"><i class="bi bi-list"></i></button>
</div>
<div class="nav-mobile-menu" id="mobileMenu">
  <div class="nav-user-info"><i class="bi bi-person-circle me-1"></i><%= loginName %> · <span class="role-chip" style="font-size:11px">관리자</span></div>
  <a href="/CAN/main_admin.jsp" class="chip"><i class="bi bi-house me-1"></i>대시보드</a>
  <form action="/CAN/logout" method="post" style="margin:0">
    <button type="submit" class="chip" style="width:100%;justify-content:center"><i class="bi bi-box-arrow-right me-1"></i>로그아웃</button>
  </form>
</div>

<div class="shell">

<div class="hero">
  <div class="hero-content">
    <div class="hero-eyebrow">// ICT CAN · 관리자</div>
    <div class="hero-title">전체 예약 <em>관리</em> 📋</div>
    <div class="hero-desc">강의실, 세미나실, 컴퓨터실 등 모든 예약을 통합 관리합니다. 필요시 관리자 권한으로 예약을 취소할 수 있습니다.</div>
  </div>
  <div class="hero-side">📅</div>
</div>

<% if(!okMsg.isEmpty()){%><div class="alert-ok"><i class="bi bi-check-circle-fill"></i><%= okMsg %></div><%}%>
<% if(!errMsg.isEmpty()){%><div class="alert-err"><i class="bi bi-exclamation-circle-fill"></i><%= errMsg %></div><%}%>

<!-- 필터 탭 -->
<div>
  <div style="font-size:12px;color:var(--txt2);font-weight:700;margin-bottom:10px;text-transform:uppercase;">공간 유형</div>
  <div class="filter-tabs">
    <a href="/CAN/reservations_admin.jsp" class="filter-tab <%= filterType.isEmpty()?"active":"" %>">전체</a>
    <a href="/CAN/reservations_admin.jsp?type=강의실" class="filter-tab <%= "강의실".equals(filterType)?"active":"" %>">강의실</a>
    <a href="/CAN/reservations_admin.jsp?type=세미나실" class="filter-tab <%= "세미나실".equals(filterType)?"active":"" %>">세미나실</a>
    <a href="/CAN/reservations_admin.jsp?type=컴퓨터실" class="filter-tab <%= "컴퓨터실".equals(filterType)?"active":"" %>">컴퓨터실</a>
    <a href="/CAN/reservations_admin.jsp?type=자산" class="filter-tab <%= "자산".equals(filterType)?"active":"" %>">자산</a>
  </div>
</div>

<div style="margin-bottom:20px;">
  <div style="font-size:12px;color:var(--txt2);font-weight:700;margin-bottom:10px;text-transform:uppercase;">상태</div>
  <div class="filter-tabs">
    <a href="/CAN/reservations_admin.jsp<%= !filterType.isEmpty()?"?type="+java.net.URLEncoder.encode(filterType,"UTF-8"):"" %>" class="filter-tab <%= filterStatus.isEmpty()?"active":"" %>">전체</a>
    <a href="/CAN/reservations_admin.jsp?status=예약완료<%= !filterType.isEmpty()?"&type="+java.net.URLEncoder.encode(filterType,"UTF-8"):"" %>" class="filter-tab <%= "예약완료".equals(filterStatus)?"active":"" %>">예약완료</a>
    <a href="/CAN/reservations_admin.jsp?status=취소<%= !filterType.isEmpty()?"&type="+java.net.URLEncoder.encode(filterType,"UTF-8"):"" %>" class="filter-tab <%= "취소".equals(filterStatus)?"active":"" %>">취소</a>
    <a href="/CAN/reservations_admin.jsp?status=완료<%= !filterType.isEmpty()?"&type="+java.net.URLEncoder.encode(filterType,"UTF-8"):"" %>" class="filter-tab <%= "완료".equals(filterStatus)?"active":"" %>">완료</a>
  </div>
</div>

<!-- 예약 테이블 -->
<div class="card">
  <div class="card-head">
    <div class="ch-icon si-amber"><i class="bi bi-calendar-check" style="color:var(--amber)"></i></div>
    <div><div class="ch-title">전체 예약 관리</div><div class="ch-sub">모든 시설의 예약 조회 · 관리자 취소 가능</div></div>
  </div>
  <% if(allReserves.isEmpty()){%>
  <div class="card-body" style="text-align:center;padding:40px;color:var(--txt3)">조회된 예약이 없습니다.</div>
  <%}else{%>
  <div style="overflow-x:auto">
    <table class="tbl">
      <thead>
        <tr><th>#</th><th>공간</th><th>신청자</th><th>날짜</th><th>시간</th><th>사용목적</th><th>상태</th><th>관리자 취소</th></tr>
      </thead>
      <tbody>
      <%for(Map<String,String> rv:allReserves){
          String st=rv.get("status");
          String bc=st.contains("취소")?"badge-busy":st.contains("완료")?"badge-ok":"badge-warn";
      %>
      <tr>
        <td style="font-family:var(--mono);font-size:12px;color:var(--txt3)"><%= rv.get("id") %></td>
        <td><strong style="font-size:13px"><%= rv.get("name") %></strong>
            <div style="font-size:11px;color:var(--txt3)"><%= rv.get("type") %></div></td>
        <td><strong style="font-size:13px"><%= rv.get("uname") %></strong>
            <div style="font-size:11px;color:var(--txt3);font-family:var(--mono)"><%= rv.get("uid") %></div></td>
        <td style="font-family:var(--mono);font-size:12px"><%= rv.get("date") %></td>
        <td style="font-family:var(--mono);font-size:12px"><%= rv.get("start") %>~<%= rv.get("end") %></td>
        <td style="font-size:12px"><%= rv.get("purpose").isEmpty()?"-":rv.get("purpose") %></td>
        <td><span class="<%= bc %>"><%= st %></span></td>
        <td>
          <%if("예약완료".equals(st)){
              String rtype=rv.get("rtype")!=null?rv.get("rtype"):"asset";
          %>
          <form method="post" action="/CAN/reservations_admin.jsp" style="margin:0"
                onsubmit="return confirm('[관리자] 예약 #<%= rv.get("id") %>을(를) 취소하시겠습니까?')">
            <input type="hidden" name="act" value="cancelReserve">
            <input type="hidden" name="reserveId" value="<%= rv.get("id") %>">
            <input type="hidden" name="type" value="<%= rtype %>">
            <button type="submit" class="btn-danger"><i class="bi bi-x-circle"></i>취소</button>
          </form>
          <%}else{%><span style="font-size:12px;color:var(--txt3)">-</span><%}%>
        </td>
      </tr>
      <%}%>
      </tbody>
    </table>
  </div>
  <%}%>
</div>

</div>
<footer class="site-footer">
  <div class="footer-inner">
    <a href="/CAN/campuslogin.jsp" class="footer-logo"><span class="footer-logo-dot"><img src="/CAN/images/logo.png" alt="ICT"></span>ICT <em>CAN</em></a>
    <div class="footer-team"><strong>Made by AI 소프트웨어학과</strong><br>박승순 &middot; 권동해 &middot; 원태연 &middot; 이수혁</div>
    <div class="footer-copy">ICT폴리텍대학 교내 자원 내비게이션 시스템<br>Copyright &copy; 2026 ICT CAN. All rights reserved.</div>
  </div>
</footer>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
function toggleMenu(){document.getElementById('mobileMenu').classList.toggle('open');}
</script>
</body>
</html>
