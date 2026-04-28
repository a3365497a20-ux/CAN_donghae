<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="true" import="java.sql.*,java.util.*" %>
<%
    String loginUser=(String)session.getAttribute("loginUser");
    String loginName=(String)session.getAttribute("loginName");
    if(loginUser==null){response.sendRedirect("/CAN/campuslogin.jsp");return;}
    if(!"admin".equals(session.getAttribute("loginRole"))){response.sendRedirect("/CAN/campuslogin.jsp");return;}

    final String DBURL="jdbc:mysql://localhost:3306/campusnav?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8&allowPublicKeyRetrieval=true";

    String okMsg="",errMsg="";
    String filterYear=request.getParameter("year");if(filterYear==null)filterYear="";
    String filterType=request.getParameter("type");if(filterType==null)filterType="";

    // ── POST 처리 (폐기 등록) ──
    if("POST".equals(request.getMethod())){
        request.setCharacterEncoding("UTF-8");
        String act=request.getParameter("act");
        if("addDisposal".equals(act)){
            String assetNo=request.getParameter("d_asset_no");
            String dispDate=request.getParameter("d_date");
            String dispType=request.getParameter("d_type");
            String remark=request.getParameter("d_remark");

            if(assetNo==null||assetNo.trim().isEmpty()||dispDate==null||dispDate.trim().isEmpty()){
                errMsg="자산번호와 폐기일자는 필수입니다.";
            } else {
                try{
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    Connection c=DriverManager.getConnection(DBURL,"root","1234");
                    // 자산 존재 확인
                    PreparedStatement ck=c.prepareStatement("SELECT item_name FROM assets WHERE asset_no=?");
                    ck.setString(1,assetNo.trim());ResultSet rck=ck.executeQuery();
                    if(!rck.next()){errMsg="자산번호 ["+assetNo+"] 이(가) 없습니다.";}
                    else{
                        String iname=rck.getString(1);rck.close();ck.close();
                        PreparedStatement ps=c.prepareStatement(
                            "INSERT INTO asset_disposal(asset_no,item_name,disposal_date,disposal_type,remark) VALUES(?,?,?,?,?)");
                        ps.setString(1,assetNo.trim());ps.setString(2,iname);
                        ps.setString(3,dispDate.trim());ps.setString(4,dispType!=null?dispType:"");
                        ps.setString(5,remark!=null?remark:"");
                        ps.executeUpdate();ps.close();
                        okMsg="폐기 내역 등록 완료! ["+assetNo+"] "+iname;
                    }
                    c.close();
                }catch(Exception e){errMsg="폐기 등록 오류: "+e.getMessage();}
            }
        }
    }

    // ── 폐기 목록 조회 ──
    List<Map<String,String>> disposals=new ArrayList<>();
    try{
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn=DriverManager.getConnection(DBURL,"root","1234");

        String sql="SELECT disposal_id,asset_no,item_name,disposal_year,disposal_type,disposal_date,remark FROM asset_disposal WHERE 1=1";
        if(!filterYear.isEmpty()){
            sql+=" AND disposal_year='"+filterYear+"'";
        }
        if(!filterType.isEmpty()){
            sql+=" AND disposal_type='"+filterType+"'";
        }
        sql+=" ORDER BY disposal_date DESC LIMIT 100";

        ResultSet rs=conn.createStatement().executeQuery(sql);
        while(rs.next()){
            Map<String,String> m=new LinkedHashMap<>();
            m.put("id",rs.getString("disposal_id")!=null?rs.getString("disposal_id"):"");
            m.put("assetNo",rs.getString("asset_no")!=null?rs.getString("asset_no"):"");
            m.put("name",rs.getString("item_name")!=null?rs.getString("item_name"):"");
            m.put("year",rs.getString("disposal_year")!=null?rs.getString("disposal_year"):"");
            m.put("type",rs.getString("disposal_type")!=null?rs.getString("disposal_type"):"");
            m.put("date",rs.getString("disposal_date")!=null?rs.getString("disposal_date"):"");
            m.put("remark",rs.getString("remark")!=null?rs.getString("remark"):"");
            disposals.add(m);
        }
        rs.close();conn.close();
    }catch(Exception e){errMsg+="조회오류: "+e.getMessage();}
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ICT CAN — 폐기 처리</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,700;9..40,800&family=DM+Mono:wght@400;500&family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/CAN/css/common.css">
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
    <div class="hero-title">자산 폐기 <em>관리</em> 🗑️</div>
    <div class="hero-desc">노후되거나 손상된 자산의 폐기 처리 내역을 관리합니다. 폐기 새 내역을 등록하거나 전체 폐기 현황을 조회할 수 있습니다.</div>
  </div>
  <div class="hero-side">♻️</div>
</div>

<% if(!okMsg.isEmpty()){%><div class="alert-ok"><i class="bi bi-check-circle-fill"></i><%= okMsg %></div><%}%>
<% if(!errMsg.isEmpty()){%><div class="alert-err"><i class="bi bi-exclamation-circle-fill"></i><%= errMsg %></div><%}%>

<div class="row g-4">
  <div class="col-xl-7">

    <!-- 폐기 내역 등록 -->
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-purple"><i class="bi bi-plus-circle" style="color:var(--purple)"></i></div>
        <div><div class="ch-title">폐기 내역 등록</div><div class="ch-sub">새로운 폐기 처리를 기록합니다</div></div>
      </div>
      <div class="card-body">
        <form method="post" action="/CAN/disposal_admin.jsp">
          <input type="hidden" name="act" value="addDisposal">
          <div class="row g-3">
            <div class="col-md-6">
              <label class="f-label">자산번호 *</label>
              <input class="f-input" type="text" name="d_asset_no" placeholder="예) 8402C0001" required>
            </div>
            <div class="col-md-6">
              <label class="f-label">폐기일자 *</label>
              <input class="f-input" type="date" name="d_date" required>
            </div>
            <div class="col-12">
              <label class="f-label">폐기 사유</label>
              <input class="f-input" type="text" name="d_type" placeholder="예) 노후, 손상, 기술낙후">
            </div>
            <div class="col-12">
              <label class="f-label">비고</label>
              <textarea class="f-input" name="d_remark" placeholder="폐기 처리 상세 내용" style="min-height:80px;resize:vertical"></textarea>
            </div>
            <div class="col-12">
              <button type="submit" class="btn-success"><i class="bi bi-check-circle me-1"></i>폐기 내역 등록</button>
            </div>
          </div>
        </form>
      </div>
    </div>

    <!-- 폐기 목록 -->
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-purple"><i class="bi bi-trash" style="color:var(--purple)"></i></div>
        <div><div class="ch-title">폐기 처리 현황</div><div class="ch-sub">최근 100건 · 폐기일 기준 정렬</div></div>
      </div>
      <% if(disposals.isEmpty()){%>
      <div class="card-body" style="text-align:center;padding:40px;color:var(--txt3)">폐기 내역이 없습니다.</div>
      <%}else{%>
      <div style="overflow-x:auto">
        <table class="tbl">
          <thead>
            <tr><th>#</th><th>자산명</th><th>자산번호</th><th>폐기일</th><th>사유</th><th>비고</th></tr>
          </thead>
          <tbody>
          <%for(Map<String,String> d:disposals){%>
          <tr>
            <td style="font-family:var(--mono);font-size:12px;color:var(--txt3)"><%= d.get("id") %></td>
            <td><strong style="font-size:13px"><%= d.get("name") %></strong></td>
            <td style="font-family:var(--mono);font-size:12px"><%= d.get("assetNo") %></td>
            <td style="font-family:var(--mono);font-size:12px"><%= d.get("date") %></td>
            <td style="font-size:12px"><%= d.get("type").isEmpty()?"-":d.get("type") %></td>
            <td style="font-size:12px;max-width:300px;word-break:break-word"><%= d.get("remark").isEmpty()?"-":d.get("remark") %></td>
          </tr>
          <%}%>
          </tbody>
        </table>
      </div>
      <%}%>
    </div>
  </div>

  <div class="col-xl-5">
    <!-- 통계 -->
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-purple"><i class="bi bi-bar-chart" style="color:var(--purple)"></i></div>
        <div><div class="ch-title">폐기 통계</div></div>
      </div>
      <div class="card-body" style="padding:12px 22px">
        <ul style="list-style:none;padding:0;margin:0">
          <li style="display:flex;justify-content:space-between;padding:12px 0;border-bottom:1px solid var(--line);font-size:14px">
            <span style="color:var(--txt2)">총 폐기 건수</span><span style="font-weight:700;font-family:var(--mono);color:var(--purple)"><%= disposals.size() %>건</span>
          </li>
        </ul>
      </div>
    </div>

    <!-- 빠른 링크 -->
    <div class="card">
      <div class="card-head">
        <div class="ch-icon si-blue"><i class="bi bi-lightning" style="color:var(--blue)"></i></div>
        <div><div class="ch-title">빠른 이동</div></div>
      </div>
      <div class="card-body">
        <div style="display:grid;grid-template-columns:1fr;gap:10px">
          <a href="/CAN/main_admin.jsp" style="display:block;text-align:center;background:var(--blue-lt);border:1.5px solid var(--blue-md);border-radius:var(--r);padding:16px;text-decoration:none;color:var(--blue);font-weight:700;font-size:14px"><i class="bi bi-house-fill d-block mb-1" style="font-size:20px"></i>관리자 대시보드</a>
          <a href="/CAN/asset_manage.jsp" style="display:block;text-align:center;background:var(--teal-lt);border:1.5px solid var(--teal-md);border-radius:var(--r);padding:16px;text-decoration:none;color:var(--teal);font-weight:700;font-size:14px"><i class="bi bi-pencil-square d-block mb-1" style="font-size:20px"></i>자산 관리</a>
          <a href="/CAN/reservations_admin.jsp" style="display:block;text-align:center;background:var(--amber-lt);border:1.5px solid #fde68a;border-radius:var(--r);padding:16px;text-decoration:none;color:var(--amber);font-weight:700;font-size:14px"><i class="bi bi-calendar-check d-block mb-1" style="font-size:20px"></i>예약 관리</a>
        </div>
      </div>
    </div>
  </div>
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
