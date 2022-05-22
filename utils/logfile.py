import numpy as np
import matplotlib.pyplot as plt

class log_file:
    
    def __init__(self, inp):
        self.filename = inp
        self.parse()
    
    def parse(self):
        with open(self.filename, "r") as f:
            # Line 1 parsing
            inp = f.readline().split(' ')
            if(len(inp) != 3):
                return False, "Line 1 must be in format <rotationSystem> <controlMode> test"
            
            if(inp[0] == "Hyperbolic"):
                self.hyp  = True
                self.circ = False
            elif(inp[0] == "Circular"):
                self.hyp  = False
                self.circ  = True
            else:
                return False, "Line 1 : rotationSystem '%s' not recognized"%(inp[0])
            
            if(inp[1] == "rotation"):
                self.rot  = True
                self.vect  = False
            elif(inp[1] == "vectoring"):
                self.rot  = False
                self.vect  = True
            else:
                return False, "Line 1 : controlMode '%s' not recognized"%(inp[1])

            # Skip Line 2
            f.readline()

            # Line 3
            inp = f.readline().split(':')
            if(len(inp) != 2 or inp[0].strip() != "Number of tests"):
                return False, "Line 3 must be Number of tests"
            self.num_tests = int(inp[1])

            # Line 4
            inp = f.readline().split(':')
            if(len(inp) != 2 or inp[0].strip() != "Number of CORDIC iterations"):
                return False, "Line 4 must be Number of CORDIC iterations"
            self.num_iter = int(inp[1])

            # Line 5
            inp = f.readline().split(':')
            if(len(inp) != 2 or inp[0].strip() != "Number format"):
                return False, "Line 5 must be Number format"
            if(len(inp[1].split('.')) != 2 or inp[1].strip()[0] != 'q'):
                return False, "Line 5 : '%s' : unidentified format. use qn.m format"%(inp[1])
            self.int_bits  = int(inp[1].split('.')[0].strip()[1:])
            self.frac_bits = int(inp[1].split('.')[1])

            # Line 6
            inp = f.readline().split(':')
            if(len(inp) != 2 or inp[0].strip() != "CORDIC iteration logging"):
                return False, "Line 6 must be CORDIC iteration logging"
            self.log_iter = True if inp[1].strip() == "ON" else False

            # Line 7
            inp = f.readline().split(':')
            if(len(inp) != 2 or inp[0].strip() != "Test logging"):
                return False, "Line 7 must be Test logging"
            self.log_tests = True if inp[1].strip() == "ON" else False

            # Find test table
            self.table_found = False
            inp = f.readline().strip()
            while(inp != "Test table"):
                inp = f.readline().strip()

            if(inp == "Test table"):
                table_found = True
            else:
                return
            
            f.readline()

            self.idx_hist = []
            self.inp_hist = []
            self.exp_hist = []
            self.err_hist = []
            self.sta_hist = []
            self.xov_hist = []
            self.yov_hist = []
            self.zov_hist = []
            self.ovi_hist = []
            self.sta_hist = []

            for i in range(self.num_tests):
                inp = f.readline().strip().split(':')
                if(inp[0][0] == '-'):
                    break

                if(len(inp) != 3):
                    print("ERR")

                dat = inp[1].split('|')

                if(len(dat) != 3):
                    print("ERR")

                self.idx_hist.append(int(inp[0]))
                self.inp_hist.append(tuple(map(float, dat[0].split(','))))
                self.exp_hist.append(tuple(map(float, dat[1].split(','))))
                self.err_hist.append(tuple(map(float, dat[2].split(','))))
                self.xov_hist.append(True if inp[2].split(',')[0].strip()[0] == "1" else False)
                self.yov_hist.append(True if inp[2].split(',')[0].strip()[1] == "1" else False)
                self.zov_hist.append(True if inp[2].split(',')[0].strip()[2] == "1" else False)
                self.ovi_hist.append(int(inp[2].split(',')[1]))
                # self.sta_hist.append(True if int(inp[2].split(',')[1]) == -1 else False)
                self.sta_hist.append(inp[2].split(',')[0].strip()[0:2] == "00" if self.circ else int(inp[2].split(',')[1]) == -1)

            self.inp_good, self.inp_fail = self.separate(self.inp_hist)
            self.err_good, self.err_fail = self.separate(self.err_hist)
            self.exp_good, self.exp_fail = self.separate(self.exp_hist)
        
    def separate(self, inp_list):
        good_list   = np.asarray([inp_list[i] for i in range(len(inp_list)) if self.sta_hist[i]])
        fail_list   = np.asarray([inp_list[i] for i in range(len(inp_list)) if not self.sta_hist[i]])
        return good_list, fail_list

    def vis_rot_inputs(self):
        plt.figure(figsize=(30, 10), dpi=80)

        # Scatter plot for input coordintates
        plt.subplot(131)
        plt.scatter(self.inp_good[:, 0], self.inp_good[:, 1], s=5,  marker="o", c="green", label="Success")
        if(len(self.exp_fail) != 0): plt.scatter(self.inp_fail[:, 0], self.inp_fail[:, 1], s=10, marker="x", c="red",   label="Overflow")

        plt.xlabel("Input x coordinate")
        plt.ylabel("Input y coordinate")
        plt.title("Input coordinates")
        plt.legend()

        # Scatter plot for input coordinate magnitude and input rotation angle
        plt.subplot(132)
        plt.scatter(self.inp_good[:, 2], np.linalg.norm(self.inp_good[:, 0:2], axis=1), s=5,  marker="o", c="green", label="Success")
        if(len(self.exp_fail) != 0): plt.scatter(self.inp_fail[:, 2], np.linalg.norm(self.inp_fail[:, 0:2], axis=1), s=10, marker="x", c="red",   label="Overflow")
        
        plt.xlabel("Input angle")
        plt.ylabel("Input coordinate magnitude")
        plt.title("Input rotation angle and input coordinate magnitude")
        plt.legend()

        # Scatter plot for expected coordinates
        plt.subplot(133)
        plt.scatter(self.exp_good[:, 0], self.exp_good[:, 1], s=5,  marker="o", c="green", label="Success")
        if(len(self.exp_fail) != 0): plt.scatter(self.exp_fail[:, 0], self.exp_fail[:, 1], s=10, marker="x", c="red",   label="Overflow")

        plt.xlabel("Expected x coordinate")
        plt.ylabel("Expected y coordinate")
        plt.title("Expected output coordinates")
        plt.legend()

        plt.show()

    def vis_vect_inputs(self):
        plt.figure(figsize=(30, 10), dpi=80)

        # Scatter plot for input coordintates
        plt.subplot(131)
        plt.scatter(self.inp_good[:, 0], self.inp_good[:, 1], s=5,  marker="o", c="green", label="Success")
        if(len(self.exp_fail) != 0): plt.scatter(self.inp_fail[:, 0], self.inp_fail[:, 1], s=10, marker="x", c="red",   label="Overflow")

        plt.xlabel("Input x coordinate")
        plt.ylabel("Input y coordinate")
        plt.title("Input coordinates")
        plt.legend()

        # Scatter plot for input coordinate magnitude and initial angle
        plt.subplot(132)
        plt.scatter(self.inp_good[:, 2], np.linalg.norm(self.inp_good[:, 0:2], axis=1), s=5,  marker="o", c="green", label="Success")
        if(len(self.exp_fail) != 0): plt.scatter(self.inp_fail[:, 2], np.linalg.norm(self.inp_fail[:, 0:2], axis=1), s=10, marker="x", c="red",   label="Overflow")
        
        plt.xlabel("Input angle")
        plt.ylabel("Input coordinate magnitude")
        plt.title("Input rotation angle and input coordinate magnitude")
        plt.legend()

        # Scatter plot for expected x and expected angle
        plt.subplot(133)
        plt.scatter(np.arctan2(self.inp_good[:,1], self.inp_good[:, 0]), self.exp_good[:, 0], s=5,  marker="o", c="green", label="Success")
        if(len(self.exp_fail) != 0): plt.scatter(np.arctan2(self.inp_fail[:,1], self.inp_fail[:, 0]), self.exp_fail[:, 0], s=5,  marker="o", c="red", label="Overflow")
        # plt.scatter(self.exp_good[:, 2], self.exp_good[:, 0], s=5,  marker="o", c="green", label="Success")
        # if(len(self.exp_fail) != 0): plt.scatter(self.exp_fail[:, 2], self.exp_fail[:, 0], s=10, marker="x", c="red",   label="Overflow")

        plt.xlabel("Input coordinate angle")
        plt.ylabel("Expected x coordinate output")
        plt.title("Input rotation angle and input coordinate magnitude")
        plt.legend()

        plt.show()

    def vis_rot_error(self):        
        x_err_dB   = 20 * np.log10(np.abs(self.err_good[:, 0]))
        y_err_dB   = 20 * np.log10(np.abs(self.err_good[:, 1]))
        ang_err_dB = 20 * np.log10(np.maximum(1e-10, np.abs(self.err_good[:, 2])) / 180)
        mag_err_dB = 20 * np.log10(np.linalg.norm(self.err_good[:, 0:2], axis=1))

        plt.figure(figsize=(30, 10), dpi=80)
        
        # Input angle v/s magnitude error
        plt.subplot(131)
        plt.scatter(self.inp_good[:, 2], ang_err_dB, s=5)
        plt.ylim((-250, 0))
        plt.xlabel("Input angle (degrees)")
        plt.ylabel("Angle residual (dB)")
        plt.title("Input angle v/s angle residual")
            
        # Input angle v/s angle residual
        plt.subplot(132)
        plt.scatter(self.inp_good[:, 2], mag_err_dB, s=5)
        plt.ylim((-250, 0))
        plt.xlabel("Input angle (degrees)")
        plt.ylabel("Magnitude error (dB)")
        plt.title("Input angle v/s angle residual")
            
        plt.subplot(133)
        plt.hist(mag_err_dB, density = True, bins=30, histtype='step', label="Magnitude error")
        plt.hist(ang_err_dB, density = True, bins=30, histtype='step', label="Angle error")
        plt.xlim((-250, 0))
        plt.xlabel("Error (dB)")
        plt.ylabel("Density")
        plt.legend()
        plt.title("Error histogram")

        plt.show()

    def vis_vect_error(self):
        x_err_dB   = 20 * np.log10(np.abs(self.err_good[:, 0]))
        y_err_dB   = 20 * np.log10(np.maximum(1e-15, np.abs(self.err_good[:, 1])))
        ang_err_dB = 20 * np.log10(np.maximum(1e-10, np.abs(self.err_good[:, 2])) / 180)
        mag_err_dB = 20 * np.log10(np.linalg.norm(self.err_good[:, 0:2], axis=1))

        plt.figure(figsize=(30, 10), dpi=80)
        
        # Expected angle v/s angle error
        plt.subplot(131)
        plt.scatter(self.exp_good[:, 2], ang_err_dB, s=5)
        plt.ylim((-250, 0))
        plt.xlabel("Expected angle (degrees)")
        plt.ylabel("Angle error (dB)")
        plt.title("Expected angle v/s angle error")
            
        # Expected angle v/s magnitude error
        plt.subplot(132)
        plt.scatter(self.exp_good[:, 2], y_err_dB, s=5)
        plt.ylim((-250, 0))
        plt.xlabel("Expected angle (degrees)")
        plt.ylabel("y error (dB)")
        plt.title("Expected angle v/s angle error")

        # Histogram of errors
        plt.subplot(133)
        plt.hist(x_err_dB, density = True, bins=30, histtype='step', label="X error")
        plt.hist(ang_err_dB, density = True, bins=30, histtype='step', label="Angle error")
        plt.hist(y_err_dB, density = True, bins=30, histtype='step', label="y residual")
        plt.xlim((-250, 0))
        plt.xlabel("Error (dB)")
        plt.ylabel("Density")
        plt.legend()
        plt.title("Error histogram")

        plt.show()

    def vis_inputs(self):
        if(self.rot):
            self.vis_rot_inputs()
        else:
            self.vis_vect_inputs()

    def vis_error(self):
        if(self.rot):
            self.vis_rot_error()
        else:
            self.vis_vect_error()

    def get_description(self):
        temp = ""
        temp = temp + ("Circular" if self.circ else "Hyperbolic") + " "
        temp = temp + ("Rotation" if self.rot else "Vectoring") + " test "
        temp = temp + "with " + str(self.num_tests) + " tests of "
        temp = temp + str(self.num_iter) + " iterations each"

        return temp

# Pass filenames to directly visualize them using these functions
 
def vis_rot_inputs_file(filename):
    l = log_file(filename)
    l.vis_rot_inputs()

def vis_rot_error_file(filename):
    l = log_file(filename)
    l.vis_rot_error()

def vis_rotation_file(filename):
    l = log_file(filename)
    l.vis_rot_inputs()
    l.vis_rot_error()

def vis_vect_inputs_file(filename):
    l = log_file(filename)
    l.vis_vect_inputs()

def vis_vect_error_file(filename):
    l = log_file(filename)
    l.vis_vect_error()

def vis_vectoring_file(filename):
    l = log_file(filename)
    l.vis_vect_inputs()
    l.vis_vect_error()
