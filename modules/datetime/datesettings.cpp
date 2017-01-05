#include "datesettings.h"

#include <QVBoxLayout>
#include <QPushButton>
#include <QDebug>
#include <QDate>

#include "clock.h"
#include "datetimewidget.h"
#include "datetimemodel.h"

#include "settingsgroup.h"
#include "settingsitem.h"
#include "contentwidget.h"
#include "switchwidget.h"
#include "nextpagewidget.h"
#include "translucentframe.h"
#include "clockitem.h"
#include "timezone_dialog/timezonechooser.h"

using namespace dcc;
using namespace dcc::widgets;

namespace dcc {
namespace datetime {

DateSettings::DateSettings(QWidget *parent)
    :ContentWidget(parent),
      m_datetimeGroup(new SettingsGroup),
      m_clock(new ClockItem),
      m_timeWidget(new TimeWidget),
      m_yearWidget(new DateWidget(DateWidget::Year, 1970, 9999)),
      m_monthWidget(new DateWidget(DateWidget::Month, 1, 12)),
      m_dayWidget(new DateWidget(DateWidget::Day, 1, 31)),
      m_cancelButton(new QPushButton(tr("Cancel"))),
      m_confirmButton(new QPushButton(tr("Confirm"))),
      m_timezoneGroup(new SettingsGroup),
      m_timezoneItem(new NextPageWidget),
      m_dialog(new TimeZoneChooser)
{
    setTitle(tr("Change Time Settings"));

    QDate date ( QDate::currentDate() );
    m_yearWidget->setValue(date.year());
    m_monthWidget->setValue(date.month());
    m_dayWidget->setValue(date.day());

    TranslucentFrame *widget = new TranslucentFrame;
    QVBoxLayout* layout = new QVBoxLayout(widget);
    layout->setSpacing(1);
    layout->setMargin(0);

    m_datetimeGroup->appendItem(m_clock);
    m_datetimeGroup->appendItem(m_timeWidget);
    m_datetimeGroup->appendItem(m_yearWidget);
    m_datetimeGroup->appendItem(m_monthWidget);
    m_datetimeGroup->appendItem(m_dayWidget);

    QHBoxLayout *buttonLayout = new QHBoxLayout;
    buttonLayout->setMargin(0);
    buttonLayout->setSpacing(1);
    buttonLayout->addWidget(m_cancelButton);
    buttonLayout->addWidget(m_confirmButton);

    m_timezoneItem->setTitle(tr("Change System Timezone"));
    m_timezoneGroup->appendItem(m_timezoneItem);

    layout->addWidget(m_datetimeGroup);
    layout->addSpacing(10);
    layout->addLayout(buttonLayout);
    layout->addSpacing(10);
    layout->addWidget(m_timezoneGroup);

    setContent(widget);

    connect(m_cancelButton, &QPushButton::clicked, this, &DateSettings::onCancelButtonClicked);
    connect(m_confirmButton, &QPushButton::clicked, this, &DateSettings::onConfirmButtonClicked);

    connect(m_timezoneItem, &NextPageWidget::clicked, this, [this] {
        emit requestHold();
        m_dialog->show();
    });
    connect(m_dialog, &TimeZoneChooser::confirmed, this, [this] (const QString &timezone) {
        emit requestSetTimeZone(timezone);
        back();
        emit requestUnhold();
    });
    connect(m_dialog, &TimeZoneChooser::cancelled, this, [this] {
        emit requestUnhold();
    });

    connect(m_monthWidget, &DateWidget::editingFinished, this, &DateSettings::updateDayRange);
}

void DateSettings::setModel(DatetimeModel *model)
{
    m_model = model;

    connect(model, &DatetimeModel::systemTimeZoneIdChanged, this, &DateSettings::setTimeZone);

    setTimeZone(model->systemTimeZoneId());
}

void DateSettings::onCancelButtonClicked()
{
    back();
}

void DateSettings::onConfirmButtonClicked()
{
    QDate date; date.setDate(m_yearWidget->value(), m_monthWidget->value(), m_dayWidget->value());
    QTime time; time.setHMS(m_timeWidget->hour(), m_timeWidget->minute(), 0);

    QDateTime datetime(date, time);
    emit requestSetTime(datetime);

    back();
}

void DateSettings::setTimeZone(const QString &zone)
{
    qDebug() << "sett time zone " << zone;
    m_timezoneItem->setValue(zone);
}

void DateSettings::updateDayRange()
{
    const int year = m_yearWidget->value();
    const int month = m_monthWidget->value();

    QDate date(year, month, 1);
    m_dayWidget->setRange(1, date.daysInMonth());
}

//void DateSettings::setTimezone(const QString &timezone)
//{
//    QTimeZone tz(timezone.toStdString().c_str());
//    m_timezoneItem->setValue(tz.utc().id());
//    m_clock->setTimezone(timezone);
//}

//void DateSettings::slotMonthChange(DateWidget::Type type, int data)
//{
//    if(type == DateWidget::Year)
//    {
//        QDate date(data, m_monthWidget->data(), 1);
//        int day = date.daysInMonth();
//        m_dayWidget->setMax(day);
//    }
//    else if(type == DateWidget::Month)
//    {
//        QDate date(m_yearWidget->data(), data, 1);
//        int day = date.daysInMonth();
//        m_dayWidget->setMax(day);
//    }
//    else
//    {
////        QDate date(m_monthWidget->data(), data, m_dayWidget->data());
////        int day = date.daysInMonth();
////        m_dayWidget->setMax(day);
//    }
//}

//void DateSettings::slotConfirm()
//{
//    int year = m_yearWidget->data();
//    int month = m_monthWidget->data();
//    int day = m_dayWidget->data();

//    int hour = m_timeWidget->hour();
//    int minute = m_timeWidget->minute();

//    emit dateChanged(year, month, day, hour, minute);
//}

//void DateSettings::slotCancel()
//{

//}

}
}
