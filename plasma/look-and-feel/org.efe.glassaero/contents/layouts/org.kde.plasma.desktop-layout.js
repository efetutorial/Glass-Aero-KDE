// SPDX-License-Identifier: GPL-3.0-or-later
// Optional layout: Plasma applies this only when the user selects desktop layout.
var panel = new Panel;
panel.location = "bottom";
panel.height = 46;
panel.floating = false;
panel.addWidget("org.kde.plasma.kickoff");
panel.addWidget("org.kde.plasma.pager");
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("iconSpacing", 3);
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("use24hFormat", 2);
panel.addWidget("org.kde.plasma.showdesktop");
