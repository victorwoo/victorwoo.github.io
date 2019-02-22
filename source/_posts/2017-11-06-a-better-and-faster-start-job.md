---
layout: post
date: 2017-11-06 00:00:00
title: "PowerShell 技能连载 - 一个更好（更快）的 Start-Job"
description: PowerTip of the Day - A Better (and Faster) Start-Job
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Start-Job` 将一个脚本块发送到一个新的 PowerShell 进程，这样它可以独立并行运行。以下是一个非常简单的例子，演示 job 背后的概念：

```powershell
# three separate "jobs" to do:
$job1 = { Start-Sleep -Seconds 6 ; 1 }
$job2 = { Start-Sleep -Seconds 8 ; 2 }
$job3 = { Start-Sleep -Seconds 5 ; 3 }

# execute two of them in background jobs
$j1 = Start-Job -ScriptBlock $job1
$j3 = Start-Job -ScriptBlock $job3

# execute one in our own process
$ej2 = & $job2

# wait for all to complete
$null = Wait-Job -Job $J1, $j3

# get the results and clean up
$ej1 = Receive-Job -Job $j1
$ej3 = Receive-Job -Job $j3
Remove-Job -Job $j1, $j3

# work with the results
$ej1, $ej2, $ej3
```

如果不用 job，那么需要等待 19 秒。幸好有了 job，这个过程可以缩短到 8 秒。

然而，也有副作用。由于 job 是在独立的应用中执行的，数据必须以 XML 序列化的方式来回传递。job 要传回越多的数据，就需要越多的时间。有些时候这个副作用会盖过了优点。

一个更好的方是在原来的 PowerShell 实例的子线程中运行 job。以下代码演示这种功能。它创建了一个新的名为 `Start-MemoryJob` 的命令，可以替代 `Start-Job`。其余的代码完全不用改变。

使用 `Start-MemoryJob`，不需要任何对象序列化。您的 job 可以快速平滑地运行，而没有返回大量的数据。而且，您现在获取到的是原始的对象。不再需要处理序列化过的对象。

```powershell
$code = @'
using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
namespace InProcess
{
  public class InMemoryJob : System.Management.Automation.Job
  {
  public InMemoryJob(ScriptBlock scriptBlock, string name)
  {
  _PowerShell = PowerShell.Create().AddScript(scriptBlock.ToString());
  SetUpStreams(name);
  }
  public InMemoryJob(PowerShell PowerShell, string name)
  {
  _PowerShell = PowerShell;
  SetUpStreams(name);
  }
  private void SetUpStreams(string name)
  {
  _PowerShell.Streams.Verbose = this.Verbose;
  _PowerShell.Streams.Error = this.Error;
  _PowerShell.Streams.Debug = this.Debug;
  _PowerShell.Streams.Warning = this.Warning;
  _PowerShell.Runspace.AvailabilityChanged +=
  new EventHandler<RunspaceAvailabilityEventArgs>(Runspace_AvailabilityChanged);
  int id = System.Threading.Interlocked.Add(ref InMemoryJobNumber, 1);
  if (!string.IsNullOrEmpty(name))
  {
  this.Name = name;
  }
  else
  {
  this.Name = "InProcessJob" + id;
  }
  }
  void Runspace_AvailabilityChanged(object sender, RunspaceAvailabilityEventArgs e)
  {
  if (e.RunspaceAvailability == RunspaceAvailability.Available)
  {
  this.SetJobState(JobState.Completed);
  }
  }
  PowerShell _PowerShell;
  static int InMemoryJobNumber = 0;
  public override bool HasMoreData
  {
  get {
  return (Output.Count > 0);
  }
  }
  public override string Location
  {
  get { return "In Process"; }
  }
  public override string StatusMessage
  {
  get { return "A new status message"; }
  }
  protected override void Dispose(bool disposing)
  {
  if (disposing)
  {
  if (!isDisposed)
  {
  isDisposed = true;
  try
  {
  if (!IsFinishedState(JobStateInfo.State))
  {
  StopJob();
  }
  foreach (Job job in ChildJobs)
  {
  job.Dispose();
  }
  }
  finally
  {
  base.Dispose(disposing);
  }
  }
  }
  }
  private bool isDisposed = false;
  internal bool IsFinishedState(JobState state)
  {
  return (state == JobState.Completed || state == JobState.Failed || state ==
JobState.Stopped);
  }
  public override void StopJob()
  {
  _PowerShell.Stop();
  _PowerShell.EndInvoke(_asyncResult);
  SetJobState(JobState.Stopped);
  }
  public void Start()
  {
  _asyncResult = _PowerShell.BeginInvoke<PSObject, PSObject>(null, Output);
  SetJobState(JobState.Running);
  }
  IAsyncResult _asyncResult;
  public void WaitJob()
  {
  _asyncResult.AsyncWaitHandle.WaitOne();
  }
  public void WaitJob(TimeSpan timeout)
  {
  _asyncResult.AsyncWaitHandle.WaitOne(timeout);
  }
  }
}
'@
Add-Type -TypeDefinition $code
function Start-JobInProcess
{
  [CmdletBinding()]
  param
  (
    [scriptblock] $ScriptBlock,
    $ArgumentList,
    [string] $Name
  )
  function Get-JobRepository
  {
    [cmdletbinding()]
    param()
    $pscmdlet.JobRepository
  }
  function Add-Job
  {
    [cmdletbinding()]
    param
    (
      $job
    )
    $pscmdlet.JobRepository.Add($job)
  }
  if ($ArgumentList)
  {
    $PowerShell = [PowerShell]::Create().AddScript($ScriptBlock).AddArgument($argumentlist)
    $MemoryJob = New-Object InProcess.InMemoryJob $PowerShell, $Name
  }
  else
  {
    $MemoryJob = New-Object InProcess.InMemoryJob $ScriptBlock, $Name
  }
  $MemoryJob.Start()
  Add-Job $MemoryJob
  $MemoryJob
}
```

<!--本文国际来源：[A Better (and Faster) Start-Job](http://community.idera.com/powershell/powertips/b/tips/posts/a-better-and-faster-start-job)-->
