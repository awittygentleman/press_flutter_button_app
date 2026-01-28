import sys
import firebase_admin
from firebase_admin import credentials, db
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QLabel
)
from PyQt5.QtCore import Qt, QThread, pyqtSignal
from PyQt5.QtGui import QFont
import os


# Initialize Firebase
cred = credentials.Certificate('C:\\Users\\Safouan\\press_me_app\\python_app_desktop\\firebase-admin-key.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://press-me-app-4f057-default-rtdb.firebaseio.com/'
})

# Get reference to 'likes' node
likes_ref = db.reference('likes')

class FirebaseListener(QThread):
    likes_updated = pyqtSignal(int)  # Signal to update UI
    
    def run(self):
        # Set up real-time listener
        def on_likes_change(message):
            if message.data is not None:
                self.likes_updated.emit(int(message.data))
        
        # Listen for changes
        likes_ref.listen(on_likes_change)

class LikesApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.init_ui()
        self.start_firebase_listener()
    
    def init_ui(self):
        # Window settings
        self.setWindowTitle('Press Me App - Live Likes Counter')
        self.setGeometry(100, 100, 500, 300)
        
        # Central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Layout
        layout = QVBoxLayout()
        
        # Title label
        title = QLabel('📊 Live Likes Counter')
        title.setFont(QFont('Arial', 16, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)
        
        # Likes counter label
        self.likes_label = QLabel('0')
        self.likes_label.setFont(QFont('Arial', 72, QFont.Bold))
        self.likes_label.setAlignment(Qt.AlignCenter)
        self.likes_label.setStyleSheet("color: #4CAF50;")
        layout.addWidget(self.likes_label)
        
        # Info label
        info = QLabel('🔄 Updates in real-time from Firebase')
        info.setFont(QFont('Arial', 10))
        info.setAlignment(Qt.AlignCenter)
        layout.addWidget(info)
        
        central_widget.setLayout(layout)
    
    def start_firebase_listener(self):
        # Start the listener thread
        self.listener_thread = FirebaseListener()
        self.listener_thread.likes_updated.connect(self.update_likes)
        self.listener_thread.start()
    
    def update_likes(self, likes_count):
        # Update the label with new count
        self.likes_label.setText(str(likes_count))

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = LikesApp()
    window.show()
    sys.exit(app.exec_())


    