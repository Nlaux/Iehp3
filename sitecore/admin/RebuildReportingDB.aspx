﻿<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="Sitecore.Analytics.Aggregation.History" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Xml" %>
<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.Analytics.Aggregation.History.Remoting" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="Sitecore.Diagnostics" %>
<%@ Import Namespace="Sitecore.Xml" %>
<%@ Import Namespace="Sitecore.Xdb.Configuration" %>
<%@ Import Namespace="Sitecore.ContentSearch" %>
<%@ Import Namespace="Sitecore.StringExtensions" %>

<script runat="server">

  /// <summary>
  /// Used to check if the session has been refresh.
  /// </summary>
  private const string CheckRefreshSessionTag = "CheckRefresh";

  /// <summary>
  /// The rebuild status.
  /// </summary>
  private RebuildStatus rebuildStatus;

  /// <summary>
  /// Indicates whether the page has been refreshed or not.
  /// </summary>
  private bool pageRefreshed;

  /// <summary>
  /// Gets the rebuild status.
  /// </summary>
  /// <value>
  /// The rebuild status.
  /// </value>
  public RebuildStatus RebuildStatus
  {
    get
    {
      return this.rebuildStatus ?? (this.rebuildStatus = this.ReportingManager.GetRebuildStatus());
    }
  }

  /// <summary>
  /// Gets or sets the reporting manager.
  /// </summary>
  /// <value>
  /// The reporting manager.
  /// </value>
  protected IReportingStorageManager ReportingManager { get; set; }

  /// <summary>
  /// Gets or sets the reporting manager supporting rebuild of slice of data.
  /// </summary>
  /// <value>
  /// The reporting manager supporting rebuild of slice of data.
  /// </value>
  protected IPartialReportingStorageManager PartialReportingManager { get; set; }

  /// <summary>
  /// Raises the <see cref="E:System.Web.UI.Control.Init" /> event to initialize the page.
  /// </summary>
  /// <param name="e">An <see cref="T:System.EventArgs" /> that contains the event data.</param>
  protected override void OnInit(EventArgs e)
  {
    this.CheckSecurity(false);

    bool useRemoteService = false;

    XmlNode node = Factory.GetConfigNode("reporting/remote");

    if (null != node)
    {
      useRemoteService = string.Equals(XmlUtil.GetAttribute("enabled", node), "true", StringComparison.InvariantCultureIgnoreCase);
    }

    if (useRemoteService)
    {
      this.PartialReportingManager = new ReportingStorageManagerProxy();
      this.ReportingManager = this.PartialReportingManager;
    }
    else
    {
      this.ReportingManager = Factory.CreateObject("aggregation/reportingStorageManager", true) as IReportingStorageManager;
      this.PartialReportingManager = this.ReportingManager as IPartialReportingStorageManager;
    }

    Assert.IsNotNull(this.ReportingManager, "ReportingStorageManager must be configured in the configuration file.");

    if (this.PartialReportingManager == null)
    {
      this.TimeSliceTextBox.Enabled = false;
      this.RebuildDBCheckBox.Enabled = false;
      this.RebuildIndexCheckBox.Enabled = false;
      this.PartialRebuildErrorLabel.Visible = true;
      this.PartialRebuildErrorLabel.Text = "Partial rebuild functionality is not available. To turn it on, make sure that ReportingManager implements IPartialReportingStorageManager interface.";
    }
  }

  /// <summary>
  /// Raises the <see cref="E:System.Web.UI.Page.PreLoad" /> event after post back data is loaded into the page server controls but before the <see cref="M:System.Web.UI.Control.OnLoad(System.EventArgs)" /> event.
  /// </summary>
  /// <param name="e">An <see cref="T:System.EventArgs" /> that contains the event data.</param>
  protected override void OnPreLoad([NotNull] EventArgs e)
  {
    pauseOrResumeButton.Enabled = false;
    this.CancelButton.Enabled = false;

    this.rebuildStatus = this.ReportingManager.GetRebuildStatus();
  }

  /// <summary>
  /// Handles the Load event of the Page control.
  /// </summary>
  /// <param name="sender">The source of the event.</param>
  /// <param name="e">The <see cref="EventArgs" /> instance containing the event data.</param>
  protected void Page_Load(object sender, EventArgs e)
  {
    if (!this.IsPostBack)
    {
      this.Session[CheckRefreshSessionTag] =
      Server.UrlDecode(DateTime.UtcNow.ToString(CultureInfo.InvariantCulture));
    }

    this.UpdateUiStatusAll();
  }

  /// <summary>
  /// Updates the UI for all status.
  /// </summary>
  protected void UpdateUiStatusAll()
  {
    this.rebuildStatus = this.ReportingManager.GetRebuildStatus();
    this.UpdateUiForOverallStatus();
  }

  /// <summary>
  /// Updates the UI for overall status.
  /// </summary>
  protected void UpdateUiForOverallStatus()
  {
    if (!XdbSettings.Enabled)
    {
      this.ErrorLabel.Text = "xDB is disabled. Ensure that your license supports xDB and in the SitecoreXdb.config file, set Xdb.Enabled to true.";
      this.StartButton.Enabled = false;
      this.CancelButton.Enabled = false;
      return;
    }

    var status = this.RebuildStatus;
    bool isActive = status.IsActive;

    AggregationStatusesTable.Rows.Clear();

    const int AmountOfCells = 5;

    var header1Row = new TableHeaderRow();
    var hStatuses = new TableHeaderCell
    {
      Text = "History Aggregation Statuses",
      ColumnSpan = AmountOfCells
    };

    header1Row.Cells.Add(hStatuses);
    AggregationStatusesTable.Rows.Add(header1Row);

    var header2Row = new TableHeaderRow();
    var hCellType = new TableHeaderCell { Text = "Type" };
    var hCellState = new TableHeaderCell { Text = "State" };
    var hCellProcessed = new TableHeaderCell { Text = "Processed" };
    var hCellTotal = new TableHeaderCell { Text = "EstimatedTotal" };
    var hCellException = new TableHeaderCell { Text = "Exception" };

    header2Row.Cells.AddRange(new TableCell[]
    {
      hCellType, hCellState, hCellProcessed, hCellTotal, hCellException
    });

    AggregationStatusesTable.Rows.Add(header2Row);

    if (status.AggregationStatuses != null && status.AggregationStatuses.Count > 0)
    {
      foreach (var aggStatus in status.AggregationStatuses)
      {
        TableCell[] cells = {
          new TableCell
          {
            Text = aggStatus.Type
          },
          new TableCell
          {
            Text = aggStatus.State.ToString()
          },
          new TableCell
          {
            Text = aggStatus.ProcessedRecords.ToString()
          },
          new TableCell
          {
            Text = aggStatus.EstimatedTotalRecords.ToString()
          },
          new TableCell
          {
            Text = aggStatus.Exception
          }
        };

        var row = new TableRow();
        row.Cells.AddRange(cells);
        AggregationStatusesTable.Rows.Add(row);
      }
    }
    else
    {
      TableCell[] cells = {
        new TableCell
        {
          Text = "N/A"
        },
        new TableCell
        {
          Text = "N/A"
        },
        new TableCell
        {
          Text = "N/A"
        },
        new TableCell
        {
          Text = "N/A"
        },
        new TableCell
        {
          Text = "N/A"
        }
      };

      var row = new TableRow();

      row.Cells.AddRange(cells);
      AggregationStatusesTable.Rows.Add(row);
    }

    ProcesStateLabel.Text = status.Step.ToString();
    IsActiveLabel.Text = isActive ? "Yes" : "No";
    CutoffLabel.Text = ResolveTimeString(status.CutOffDate);
    StartedAtLabel.Text = ResolveTimeString(status.Started);
    LastChangedLabel.Text = ResolveTimeString(status.LastChanged);
    TableRowError.Visible = !status.Error.IsNullOrEmpty();
    ErrorLabel.Text = status.Error;
    StartButton.Enabled = !isActive;
    CancelButton.Enabled = true;
    pauseOrResumeButton.Enabled = false;
  }

  /// <summary>
  /// Handle click event from startOrCancel button.
  /// </summary>
  /// <param name="sender">Reference to the button.</param>
  /// <param name="e">Event arguments.</param>
  protected void StartClick(object sender, EventArgs e)
  {
    this.PartialRebuildErrorLabel.Visible = false;

    var checkRefreshSessionTagSession = this.Session[CheckRefreshSessionTag];
    var checkRefreshSessionTagViewState = this.ViewState[CheckRefreshSessionTag];

    if (checkRefreshSessionTagSession != null && checkRefreshSessionTagViewState != null &&
      checkRefreshSessionTagSession.ToString() == checkRefreshSessionTagViewState.ToString())
    {
      this.Session[CheckRefreshSessionTag] = this.Server.UrlDecode(DateTime.UtcNow.ToString(CultureInfo.InvariantCulture));
    }
    else
    {
      this.pageRefreshed = true;
    }

    if (this.pageRefreshed)
    {
      return;
    }


    MissingConnStringMsg.Text = this.ValidateReportingStorageConnectionString();
    if (MissingConnStringMsg.Text.Length > 0)
    {
      return;
    }

    if (!this.RebuildIndexCheckBox.Checked && !this.RebuildDBCheckBox.Checked)
    {
      this.PartialRebuildErrorLabel.Visible = true;
      this.PartialRebuildErrorLabel.Text = "At least one checkbox has to be checked to perform partial rebuild.";
      return;
    }

    try
    {
      if (!this.ReportingManager.GetRebuildStatus().IsActive)
      {
        StartButton.Enabled = false;

        //Good old rebuild.
        if (this.PartialReportingManager == null)
        {
          RebuildReportingIndex();
          this.ReportingManager.Rebuild();

          return;
        }

        RebuildTargets targets;

        if (this.RebuildDBCheckBox.Checked)
        {
          targets = this.RebuildIndexCheckBox.Checked ? RebuildTargets.Index | RebuildTargets.ReportingDatabase : RebuildTargets.ReportingDatabase;
        }
        else
        {
          targets = RebuildTargets.Index;
        }

        //TimeSlice is not configured. Just partial rebuild possible.
        if (string.IsNullOrEmpty(this.TimeSliceTextBox.Text))
        {
          if (targets.HasFlag(RebuildTargets.Index))
          {
            RebuildReportingIndex();
          }

          this.PartialReportingManager.Rebuild(targets);

          return;
        }

        DateTime minSaveDateTime;

        //TimeSlice is defined. Moreover, partial rebuild can be requested as well.
        if (!DateTime.TryParseExact(this.TimeSliceTextBox.Text, "u", CultureInfo.InvariantCulture, DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out minSaveDateTime))
        {
          this.PartialRebuildErrorLabel.Visible = true;
          this.PartialRebuildErrorLabel.Text = "Minimum SaveDateTime string has not been recognized as a valid date in Universal sortable date/time pattern (\"yyyy-MM-dd HH:mm:ssZ\").";

          return;
        }

        if (targets.HasFlag(RebuildTargets.Index))
        {
          RebuildReportingIndex();
        }

        this.PartialReportingManager.RebuildTimeSlice(minSaveDateTime, targets);
      }
    }
    catch (Exception exception)
    {
      MissingConnStringMsg.Text = exception.Message;
    }
  }

  private void RebuildReportingIndex()
  {
    var index = ContentSearchManager.GetAnalyticsIndex();

    if (index != null)
    {
      index.Rebuild();
    }
  }

  [NotNull]
  private string ValidateReportingStorageConnectionString()
  {
    try
    {
      ReportingStorageManagerProxy proxy = (this.ReportingManager as ReportingStorageManagerProxy);

      if (proxy != null)
      {
        proxy.CheckConfiguration();
      }
      else
      {
        ReportingStorageManagerHelper.VerifyConfiguration();
      }
    }
    catch (ReportingStorageManagerConfigurationException ex)
    {
      return ex.Message;
    }

    return string.Empty;
  }

  /// <summary>
  /// Handle click event from cancel button.
  /// </summary>
  /// <param name="sender">Reference to the button.</param>
  /// <param name="e">Event arguments.</param>
  protected void CancelClick(object sender, EventArgs e)
  {
    // important note: see the limitations in the remarks of the CancelRebuild method.
    this.ReportingManager.CancelRebuild();
  }

  /// <summary>
  /// Handle click event from pauseOrResume button.
  /// </summary>
  /// <param name="sender">Reference to the button.</param>
  /// <param name="e">Event arguments.</param>
  protected void PauseOrResumeClick(object sender, EventArgs e)
  {
    // not implemented yet
  }

  /// <summary>
  /// Raises the <see cref="E:System.Web.UI.Control.PreRender" /> event.
  /// </summary>
  /// <param name="e">An <see cref="T:System.EventArgs" /> object that contains the event data.</param>
  protected override void OnPreRender(EventArgs e)
  {
    this.ViewState[CheckRefreshSessionTag] = this.Session[CheckRefreshSessionTag];
    base.OnPreRender(e);
  }

  /// <summary>
  /// Handles the Tick event of the ProgressTimer control.
  /// </summary>
  /// <param name="sender">The source of the event.</param>
  /// <param name="e">The <see cref="EventArgs"/> instance containing the event data.</param>
  protected void ProgressTimer_Tick(object sender, EventArgs e)
  {
    this.UpdateUiStatusAll();
  }

  /// <summary>
  /// Resolves the time string.
  /// </summary>
  /// <param name="utcDateTime">The UTC date time.</param>
  /// <returns>The formatted date time.</returns>
  private string ResolveTimeString(DateTime utcDateTime)
  {
    string result = DateUtil.ToServerTime(utcDateTime).ToString("yyyy-MM-dd HH:mm:ss \"GMT\"zzz");
    return result;
  }

  /// <summary>
  /// Gets a value indicating whether current user is developer.
  /// </summary>
  /// <value>
  /// <c>true</c> if current user is developer; otherwise, <c>false</c>.
  /// </value>
  private bool IsDeveloper
  {
    get
    {
      return
        this.User.IsInRole("sitecore\\developer") ||
        this.User.IsInRole("sitecore\\sitecore client developing");
    }
  }

  /// <summary>
  /// Checks the security.
  /// </summary>
  /// <param name="isDeveloperAllowed">
  /// if set to <c>true</c>, developer is allowed.
  /// </param>
  private void CheckSecurity(bool isDeveloperAllowed)
  {
    var user = Sitecore.Context.User;

    if (user.IsAdministrator)
    {
      return;
    }

    if (isDeveloperAllowed && this.IsDeveloper)
    {
      return;
    }

    var site = Sitecore.Context.Site;

    if (site != null)
    {
      Response.Redirect(string.Format(
        "{0}?returnUrl={1}",
        site.LoginPage,
        HttpUtility.UrlEncode(Request.Url.PathAndQuery)));
    }
  }

</script>
<!DOCTYPE html>

<html>
<head runat="server">
  <title>Rebuild Reporting Database</title>
  <link rel="shortcut icon" href="/sitecore/images/favicon.ico" />
  <link rel="Stylesheet" type="text/css" href="/sitecore/shell/themes/standard/default/WebFramework.css" />
  <style type="text/css">
    .wf-container {
      min-width: 950px;
      display: inline-block;
      width: auto;
    }

    .wf-content {
      padding: 2em 2em;
    }

    #wf-dropshadow-right {
      display: none;
    }

    table {
      width: 100%;
      max-width: 950px;
    }

      table.main {
        border: 1px solid #ccc;
        border-collapse: collapse;
        font-family: Tahoma;
        font-size: 14pt;
        padding: 1em 1em;
      }

        table.main td {
          font-family: Tahoma;
          font-size: 14pt;
          border: 1px solid #ccc;
          padding: 5px;
        }

        table.main th {
          font-family: Tahoma;
          font-size: 14pt;
          text-align: center;
          border: 1px solid #ccc;
          font-weight: normal;
          padding: 5px;
        }

    .wf-configsection table th {
      background-color: #ccc;
    }

    td.datacell {
      text-align: right;
      white-space: nowrap;
    }

    table.main th.dataheader {
      text-align: center;
    }

    tr.groupheader {
      background-color: #bbb;
    }

    .top1 {
      background-image: url(/sitecore/shell/themes/Standard/Images/PipelineProfiling/font_char49_red_16.png);
      background-repeat: no-repeat;
      background-position: 5px 5px;
    }

    .top2 {
      background-image: url(/sitecore/shell/themes/Standard/Images/PipelineProfiling/font_char50_orange_16.png);
      background-repeat: no-repeat;
      background-position: 5px 5px;
    }

    .top3 {
      background-image: url(/sitecore/shell/themes/Standard/Images/PipelineProfiling/font_char51_yellow_16.png);
      background-repeat: no-repeat;
      background-position: 5px 5px;
    }

    table.main td.processor {
      padding-left: 30px;
    }

    input[type="submit"], input[type="checkbox"], label {
      vertical-align: middle;
    }
  </style>
</head>
<body>
  <form id="mainForm" runat="server" class="wf-container">
    <div class="wf-content">
      <h1>Rebuild Reporting Database</h1>
      <asp:ScriptManager runat="server"></asp:ScriptManager>
      <asp:Timer ID="ProgressTimer" Interval="4000" runat="server" OnTick="ProgressTimer_Tick"></asp:Timer>
      <p />
      <p />
      <asp:Table ID="TimeSliceTable" runat="server">
        <asp:TableHeaderRow ID="TimeSliceTableHeaderRow" runat="server">
          <asp:TableHeaderCell ID="TimeSliceTableHeaderCell" runat="server" ColumnSpan="2" HorizontalAlign="Left">
            Time slice Aggregation
          </asp:TableHeaderCell>
        </asp:TableHeaderRow>
        <asp:TableRow ID="TimeSliceRow" runat="server">
          <asp:TableCell ID="TimeSliceKey" runat="server">
            Minimum SaveDateTime*:
          </asp:TableCell>
          <asp:TableCell ID="TimeSliceCell" runat="server" HorizontalAlign="Right">
            <asp:TextBox runat="server" Width="250" placeholder="yyyy-MM-dd HH:mm:ssZ" ID="TimeSliceTextBox" />
          </asp:TableCell>
        </asp:TableRow>
        <asp:TableRow ID="TimeSliceDescriptionRow" runat="server">
          <asp:TableCell ID="TimeSliceDescriptionCell" ColumnSpan="2" runat="server">
            *Minimum SaveDateTime value defines lower boundary required for data to be included into rebuild. Data saved before minimum SaveDateTime value will not be processed during rebuild. Universal sortable date/time pattern ("yyyy-MM-dd HH:mm:ssZ", e.g. 2017-10-03 09:43:10Z) must be used.
          </asp:TableCell>
        </asp:TableRow>
      </asp:Table>
      <p />
      <asp:UpdatePanel runat="server">
        <ContentTemplate>
          <asp:Button runat="server" ID="StartButton" OnClick="StartClick" Text="Start" />
          <asp:Button runat="server" ID="CancelButton" OnClick="CancelClick" Text="Cancel" />
          <asp:Button runat="server" ID="pauseOrResumeButton" OnClick="PauseOrResumeClick" Text="Pause/Resume" Visible="False" />
          <p />
          <asp:CheckBox runat="server" ID="RebuildDBCheckBox" Text="Rebuild DB" Checked="true"></asp:CheckBox>
          <asp:CheckBox runat="server" ID="RebuildIndexCheckBox" Text="Rebuild Index" Checked="true"></asp:CheckBox>
          <p />
          <asp:Label runat="server" ID="MissingConnStringMsg" ForeColor="red"></asp:Label>
          <p />
          <asp:Label runat="server" ID="PartialRebuildErrorLabel" ForeColor="red" Visible="false"></asp:Label>
          <p />

          <asp:Table ID="TableOverallStatus" runat="server">
            <asp:TableHeaderRow ID="TableHeaderOverallStatus" runat="server">
              <asp:TableHeaderCell ID="TableHeaderCellOverallStatus" runat="server" ColumnSpan="1" HorizontalAlign="Left">
              Overall Status
              </asp:TableHeaderCell>
            </asp:TableHeaderRow>

            <asp:TableRow ID="TableRowOverallState" runat="server">
              <asp:TableCell ID="TableCellOverallStateKey" runat="server">
              Process State:
              </asp:TableCell>
              <asp:TableCell ID="TableCellOverallStateValue" runat="server" HorizontalAlign="Right">
                <asp:Label runat="server" ID="ProcesStateLabel" />
              </asp:TableCell>
            </asp:TableRow>
            <asp:TableRow ID="TableRowError" runat="server">
              <asp:TableCell ID="TableCell1" runat="server">
              Last stored error:
              </asp:TableCell>
              <asp:TableCell ID="TableCell2" runat="server" HorizontalAlign="Right">
                <asp:Label runat="server" ID="ErrorLabel" />
              </asp:TableCell>
            </asp:TableRow>

            <asp:TableRow ID="TableRowIsActive" runat="server" Visible="False">
              <asp:TableCell ID="TableCellIsActiveKey" runat="server">
              Is Active:
              </asp:TableCell>
              <asp:TableCell ID="TableCellIsActiveValue" runat="server" HorizontalAlign="Right">
                <asp:Label runat="server" ID="IsActiveLabel" />
              </asp:TableCell>
            </asp:TableRow>

            <asp:TableRow ID="TableRowCutoff" runat="server" Visible="False">
              <asp:TableCell ID="TableCellCutoffKey" runat="server">
              Cutoff Time (Server Time):
              </asp:TableCell>
              <asp:TableCell ID="TableCellCutoffValue" runat="server" HorizontalAlign="Right">
                <asp:Label runat="server" ID="CutoffLabel" />
              </asp:TableCell>
            </asp:TableRow>
            <asp:TableRow ID="TableRowStartedAt" runat="server">
              <asp:TableCell ID="TableCellStartedAtKey" runat="server">
              Started at (Server Time):
              </asp:TableCell>
              <asp:TableCell ID="TableCellStartedAtValue" runat="server" HorizontalAlign="Right">
                <asp:Label runat="server" ID="StartedAtLabel" />
              </asp:TableCell>
            </asp:TableRow>
            <asp:TableRow ID="TableRowFinishedAt" runat="server">
              <asp:TableCell ID="TableCellFinishedAtKey" runat="server">
              Last Process State Change At (Server Time):
              </asp:TableCell>
              <asp:TableCell ID="TableCellFinishedAtValue" runat="server" HorizontalAlign="Right">
                <asp:Label runat="server" ID="LastChangedLabel" />
              </asp:TableCell>
            </asp:TableRow>
          </asp:Table>
          <asp:Table ID="AggregationStatusesTable" runat="server"></asp:Table>
        </ContentTemplate>
        <Triggers>
          <asp:AsyncPostBackTrigger ControlID="ProgressTimer" EventName="Tick" />
        </Triggers>
      </asp:UpdatePanel>
    </div>
  </form>
</body>
</html>