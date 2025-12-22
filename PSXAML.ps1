Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

[xml]$XAML= @'
<Window x:Class="PowerShellXAML.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:PowerShellXAML"
        mc:Ignorable="d"
        Title="MainWindow" Height="450" Width="350">
    <Grid Background="#FF000992">
        <Label Content="Create Symbolic Link" HorizontalAlignment="Center" Margin="0,10,0,0" VerticalAlignment="Top" FontSize="20" FontWeight="Bold" Foreground="White"/>
        <TextBox x:Name="sourceTxt" HorizontalAlignment="Center" Margin="0,52,0,0" TextWrapping="NoWrap" VerticalAlignment="Top" Width="206"/>
        <Button x:Name="sourceBtn" Content="Source" HorizontalAlignment="Center" Margin="0,75,0,0" VerticalAlignment="Top" Width="135"/>
        <TextBox x:Name="destinationTxt" HorizontalAlignment="Center" Margin="0,153,0,0" TextWrapping="NoWrap" VerticalAlignment="Top" Width="206"/>
        <Button x:Name="DestinationBtn" Content="Destination" HorizontalAlignment="Center" Margin="0,176,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.668,0.519" Width="134"/>
        <RadioButton x:Name="FolderRadio" Content="Folder" HorizontalAlignment="Left" Margin="145,237,0,0" VerticalAlignment="Top" IsChecked="True" Foreground="White"/>
        <RadioButton x:Name="FileRadio" Content="File" HorizontalAlignment="Left" Margin="145,252,0,0" VerticalAlignment="Top" Foreground="#FFFFFDFD"/>
        <Button x:Name="Create" Content="Create Symbolic Link" HorizontalAlignment="Center" Margin="0,306,0,0" VerticalAlignment="Top" Width="135"/>

    </Grid>
</Window>
'@ -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window' -replace 'x:Class="\S+"',''

# Check if the script is running as an administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If not running as administrator, relaunch with elevated privileges
if (-not $isAdmin) {
    # Start a new process with elevated privileges
    Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$($MyInvocation.MyCommand.Path)""" -Verb RunAs
    exit
}

$reader=(New-Object System.Xml.XmlNodeReader $XAML)
$Form=[Windows.Markup.XamlReader]::Load($reader)
$XAML.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
    Description = "Select a folder:"
    RootFolder = "MyComputer"
}

$fileselection = New-Object System.Windows.Forms.OpenFileDialog -Property @{  
    InitialDirectory = "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}" #"shell:MyComputerFolder" #[Environment]::GetFolderPath('MyComputer')  
    CheckFileExists = 0  
    ValidateNames = 0  
    FileName = "Choose Folder"  
}  


$sourceBtn.add_click(
{
    if($FolderRadio.IsChecked)
    {
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $folderPath = $folderBrowser.SelectedPath
            $sourceTxt.Text =  $folderPath
        } else {
            Write-Host "Selection cancelled."
        }
    }
    elseif($FileRadio.IsChecked)
    {
        if($fileselection.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) 
        {
            $sourceTxt.Text =  $fileselection.Filename
        }
        else {
            Write-Host "Selection cancelled."
        }
    }
})

$destinationBtn.add_click(
{
    if($FolderRadio.IsChecked)
    {
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $folderPath = $folderBrowser.SelectedPath
            $destinationTxt.Text =  $folderPath
        } else {
            Write-Host "Selection cancelled."
        }
    }
    elseif($FileRadio.IsChecked)
    {
        if($fileselection.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) 
        {
            $destinationTxt.Text =  $fileselection.Filename
        }
        else {
            Write-Host "Selection cancelled."
        }
    }

})

$Create.add_click(
{
    if($FolderRadio.IsChecked)
    {
        if (($sourceTxt.Text) -and ($destinationTxt.Text) -and (Test-Path -Path $sourceTxt.Text -PathType Container) -and (Test-Path -Path $destinationTxt.Text -PathType Container)) {
            $destFolder = $destinationTxt.Text + $sourceTxt.Text.Substring($sourceTxt.Text.LastIndexOf('\'))
            Write-Host 'The path is a folder. ' + $destFolder
            New-Item -ItemType SymbolicLink -Path $destFolder -Target $sourceTxt.Text
        } else {
            Write-Host "The path is a file or does not exist as a folder."
            [System.Windows.Forms.MessageBox]::Show("Both Source and Destination need to be Folders", 'Error', 0, 48)
        }
    }

    elseif($FileRadio.IsChecked)
    {
        if (($sourceTxt.Text) -and ($destinationTxt.Text) -and (Test-Path -Path $sourceTxt.Text -PathType Leaf) -and (Test-Path -Path $destinationTxt.Text -PathType Leaf)) {
            Write-Host "The path is a file."
            #New-Item -ItemType SymbolicLink -Path $destinationTxt.Text -Target $sourceTxt.Text
        } else {
            Write-Host "The path is a folder or does not exist as a file."
            [System.Windows.Forms.MessageBox]::Show("Both Source and Destination need to be Files", 'Error', 0, 48)
        }
    }

    
})



$Form.ShowDialog()
