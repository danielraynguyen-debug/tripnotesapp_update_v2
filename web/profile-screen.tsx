import React from 'react';
import { 
  Medal, 
  BadgeCheck, 
  Phone, 
  Mail, 
  LogOut, 
  Home, 
  Compass, 
  Bell, 
  User, 
  Plus,
  Camera
} from 'lucide-react';

const ProfileScreen = () => {
  const userInfo = [
    {
      icon: Medal,
      label: 'Hạng thành viên',
      value: 'Hạng Chì',
    },
    {
      icon: BadgeCheck,
      label: 'Họ tên',
      value: 'Nguyễn Bá Thành',
    },
    {
      icon: Phone,
      label: 'Số điện thoại',
      value: '+84946226876',
    },
    {
      icon: Mail,
      label: 'Email',
      value: 'nguyenbathanh304@gmail.com',
    },
  ];

  const navItems = [
    { icon: Home, label: 'Trang chủ', active: false },
    { icon: Compass, label: 'Hoạt động', active: false },
    { icon: null, label: '', active: false, isFab: true },
    { icon: Bell, label: 'Thông báo', active: false },
    { icon: User, label: 'Tài khoản', active: true },
  ];

  return (
    <div className="min-h-screen bg-gray-50 max-w-[428px] mx-auto relative pb-24">
      {/* Header */}
      <header className="pt-8 pb-6 text-center">
        <h1 className="text-lg font-semibold text-gray-900 tracking-wide">
          TÀI KHOẢN
        </h1>
      </header>

      {/* Avatar Section */}
      <div className="flex flex-col items-center mb-6">
        <div className="relative">
          <div className="w-24 h-24 rounded-full overflow-hidden border-4 border-white shadow-md">
            <img
              src="https://i.pravatar.cc/300"
              alt="Profile"
              className="w-full h-full object-cover"
            />
          </div>
          {/* Camera/Edit Icon */}
          <button className="absolute -bottom-1 -right-1 w-7 h-7 bg-indigo-600 rounded-full flex items-center justify-center shadow-lg">
            <Camera className="w-4 h-4 text-white" />
          </button>
        </div>
      </div>

      {/* Information Card */}
      <div className="bg-white rounded-2xl shadow-sm mx-4 p-4 flex flex-col">
        {userInfo.map((item, index) => {
          const IconComponent = item.icon;
          return (
            <React.Fragment key={index}>
              <div className="flex items-start gap-4 py-2">
                <div className="flex-shrink-0 w-10 h-10 flex items-center justify-center">
                  <IconComponent className="w-5 h-5 text-gray-500" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-[13px] text-gray-500 mb-0.5">{item.label}</p>
                  <p className="text-base font-medium text-gray-900 truncate">
                    {item.value}
                  </p>
                </div>
              </div>
              {index < userInfo.length - 1 && (
                <div className="h-px bg-gray-100 mx-2" />
              )}
            </React.Fragment>
          );
        })}
      </div>

      {/* Logout Button */}
      <button className="mt-8 mx-4 w-[calc(100%-32px)] bg-red-50 text-red-500 rounded-xl p-4 flex items-center justify-center gap-2 active:scale-[0.98] transition-transform">
        <LogOut className="w-5 h-5" />
        <span className="text-base font-semibold">Đăng xuất</span>
      </button>

      {/* App Version */}
      <p className="text-center text-xs text-gray-400 mt-6 pb-24">
        Version 1.0.492990
      </p>

      {/* Bottom Navigation Bar */}
      <nav className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[428px] bg-white rounded-t-2xl shadow-[0_-4px_20px_rgba(0,0,0,0.08)] px-2 py-3 pb-[env(safe-area-inset-bottom,12px)] z-50">
        <div className="flex items-center justify-between px-4">
          {navItems.map((item, index) => {
            if (item.isFab) {
              return (
                <div key={index} className="relative -mt-8">
                  <button className="w-14 h-14 bg-indigo-600 rounded-full flex items-center justify-center shadow-lg active:scale-95 transition-transform">
                    <Plus className="w-7 h-7 text-white" strokeWidth={2.5} />
                  </button>
                </div>
              );
            }

            const IconComponent = item.icon;
            return (
              <button
                key={index}
                className={`flex flex-col items-center gap-1 min-w-[56px] py-1 ${
                  item.active ? 'text-indigo-600' : 'text-gray-400'
                }`}
              >
                <IconComponent className="w-6 h-6" strokeWidth={item.active ? 2 : 1.5} />
                <span className={`text-[11px] ${item.active ? 'font-medium' : 'font-normal'}`}>
                  {item.label}
                </span>
              </button>
            );
          })}
        </div>
      </nav>
    </div>
  );
};

export default ProfileScreen;
