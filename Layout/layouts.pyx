from .core import Layout
from random import shuffle
import numpy as np
import matplotlib.pyplot as plt

def checkLine(p1, p2, shape):
    """
    Uses the line foing from p1 to p2 and check each pixel of base_array
    to know if they are on the right side of the line.

    Returns boolean array, with True on right side and False on left side of the line.
    """
    idxs = np.indices(shape) # Create 3D array of indices

    p1 = np.array(p1).astype(float)#.astype(float)
    p2 = np.array(p2).astype(float)

    if abs(p2[0] - p1[0])> 1e-4:
        # Calculate max column idx for each row idx based on interpolated line between two points
        max_col_idx = (idxs[0] - p1[0]) / (p2[0] - p1[0]) * (p2[1] - p1[1]) +  p1[1] 
        # Get the direction of the line
        sign = np.sign(p2[0] - p1[0])
        return idxs[1] * sign <= max_col_idx * sign
    else: # vertical line
        sign = np.sign(p2[1] - p1[1])
        return idxs[0]*sign >= p1[0]*sign
    
def createPolygon(shape, vertices):
    """
    Creates np.array with dimensions defined by shape
    Fills polygon defined by vertices with ones, all other values zero
    """
    fill = np.ones(shape).astype(bool)  # Initialize boolean array defining shape fill

    # Create check array for each edge segment, combine into fill array
    for k in range(len(vertices)):
        fill = np.all([fill, checkLine(vertices[k-1], vertices[k], shape)], axis=0)


    return fill

class Squares(Layout):
    def __init__(self,radius,sqSize, resolution, center = None, gap = 0,verbose = True):
        
        Layout.__init__(self)  
        self._sqSize = (sqSize)
        self._radius = radius
        self._res = resolution
        self._surfaces = []
        self._grid = []
        self._gap = gap
        
        if center == None:
            self._center = [float(self._res[0]-1.)/2,float(self._res[1]-1.)/2]
        else:
            self._center = center
        
        if verbose:
            self.logger.info('Creation of hexagonal layout.')
#        print('Setting up the grid.')
#        self.setupGrid()
#        print('Creation of the hexagons.' )
        self._parts = []
        if verbose:
            self.logger.info('Creation of the hexagons.' )
        self.getSquareCell()
        if verbose:
            self.logger.info('Setting up the grid.')
        self.getSquareSegments()
        if verbose:
            self.logger.info(('-> Number of segments = %g' % self.nParts))
#        self.getFirstHexagons()
#        self.drawHexagons()
#        self.getHexagons()
#        self.checkOverlaps()
        # If no gap, we need to check that the segments do not overlap
        # We recompile the segments so that there is no overlap
        # Small disparities in the segment surfaces arise
        if self._gap == 0:
            if verbose:
                self.logger.info('Removing overlaps.')
            self.removeOverlaps()
            
        self.calculateSurfaces()
        if self._gap == 0:
            if verbose:
                self.logger.info(('-> Maximum relative variation of segment surfaces = %0.3f' % (float(max(self._surfaces)-min(self._surfaces))/float(max(self._surfaces)))))

        if verbose:
            self.logger.info('Sorting segments.')
        self.sortSegments()
        
              

        
    def getSquareCell(self):
        # need to draw two hexagons manually 
        # they will be used to generate the whole pattern
        cellSize = self._sqSize
        cellSize += np.mod(cellSize,2)
        self._resCell = [cellSize]*2
        r = self._sqSize/2
        angles = np.arange(-3*np.pi/4,-11*np.pi/4,-np.pi/2)
        self._firstHex = []
        # First one
#        vertices = [ [cellSize//2+r*np.cos(a),cellSize//2+r*np.sin(a)] for a in angles]
#        vertices = map(list,(itertools.product([1, 1+self._sqSize], repeat= 2)))
#        vertices = [ [cellSize//2+r*np.cos(a),cellSize//2+r*np.sin(a)] for a in angles]

#        self._firstHex.append(createPolygon(self._resCell,vertices))
#        self._oneSqua = np.argwhere(createPolygon(self._resCell,vertices)).astype(int)
        self._oneSqua = np.argwhere(np.ones((self._sqSize,self._sqSize))).astype(int)
        # Second one
#        offsetX = (self._hexSize+self._gap)/2;
#        offsetX = offsetX-np.round(offsetX)
#        offsetY = (self._hexSize+self._gap)*np.sqrt(3)/2
#        offsetY = offsetY-np.round(offsetY)
#        vertices = [ [self._hexSize+1.+offsetX+r*np.cos(a),self._hexSize+1.+offsetY+r*np.sin(a)] for a in angles]
#        self._firstHex.append(createPolygon(self._resCell,vertices))
        
#        plt.figure(); plt.imshow(self._firstHex[0],interpolation = 'None')
#        plt.figure(); plt.imshow(self._firstHex[1],interpolation = 'None')
        


        
    def sortSegments(self,order='dist2center',rearrange = True):
        '''
            Is used to sort segments 
        '''
        # sort the hexagons based on their distance to the center
        if order == 'dist2center':
            idx = np.array(self._rparts).argsort().astype(int)
        elif order == 'angles':
            idx = np.array(self._angles).argsort().astype(int)
        elif order == 'rndm':
            idx = range(self.nParts)
            shuffle(idx)
        else:
            raise ValueError('Invalid sorting order argument.')
        if rearrange:
            self._parts = [self._parts[i] for i in idx]
            self._rparts = self._rparts[idx]
            self._grid = self._grid[idx]
            self._angles = self._angles[idx]
        return idx
    
        

    def getSquareSegments(self):
        self.nParts = 0
        ny_max = int(np.floor(float(self._radius)/self._sqSize))
        rsq = []
        self._parts = []
        self._grid = []
        self._angles = []
        x_shift = int(np.floor(self._sqSize+self._gap))
       # x_shift -= np.mod(x_shift+1,2) 
        y_shift = int(np.floor(self._gap+self._sqSize))
        #y_shift += np.mod(y_shift+1,2) 
        for y in np.arange(-ny_max-1,ny_max+1):
            ind = np.mod(y,2)
            # one out of two line is shifted
            add_shift = ind*int(0.5*(self._sqSize+self._gap))
            if (float(self._radius)/y_shift)**2-y**2 > 0:
                nx_max = int(np.floor(np.sqrt((float(self._radius)/y_shift)**2-y**2)))
            else:
                nx_max = 2
#            print '<<', nx_max, ny_max, '>>'
            for x in np.arange(-nx_max-1,nx_max+1):
                pos = [int(self._center[0]+x*x_shift+add_shift),int(self._center[1]+y*y_shift)]
                _rsq = (pos[0]-self._center[0])**2 +  (pos[1]-self._center[1])**2
                if (_rsq <= self._radius**2):
                    self._parts.append((self._oneSqua+np.array(pos)-[self._resCell[0]/2,self._resCell[0]/2]).astype(int))
                    self._grid.append(pos)
                    self.nParts += 1
                    rsq.append(_rsq)
                    self._angles.append(np.arctan2(1.*(pos[0]-self._center[0]),1.*(pos[1]-self._center[1])))

        self._parts = np.array(self._parts)
        self._grid = np.array(self._grid)
        self._angles = np.array(self._angles)
        self._rparts = np.sqrt(rsq)
        
     
  
    

         



class Hexagons(Layout):
    def __init__(self,radius,hexSize, resolution, center = None, gap = 0,verbose = True, checkOverlaps = True):
        
        Layout.__init__(self)  
        self._hexSize = hexSize
        self._radius = radius
        self._res = resolution
        self._grid = []
        self._gap = gap
        
        if center == None:
            self._center = [float(self._res[0]-1.)/2,float(self._res[1]-1.)/2]
        else:
            self._center = center

        self.logger.info('Creation of the hexagonal layout')
#        print('Setting up the grid.')
#        self.setupGrid()
#        print('Creation of the hexagons.' )
        self._parts = []

        self.logger.debug('Creation of the hexagons and removal of the center column')
        self.getHexagonCell()
        self.removeOneCol()

        self.logger.debug('Setting up the grid')
        self.getHexagonSegments()

        self.logger.info('-> Number of segments = %g' % self.nParts)
#        self.getFirstHexagons()
#        self.drawHexagons()
#        self.getHexagons()
#        self.checkOverlaps()
        # We need to check that the segments do not overlap
        if checkOverlaps and self.checkOverlaps():
        
            # We recompile the segments so that there is no overlap
            # Small disparities in the segment surfaces arise
            self.logger.debug('Removing overlaps')
            self.removeOverlaps()
                
        self.calculateSurfaces()
        if self._gap == 0:
            self.logger.debug('-> Maximum relative variation of segment surfaces = %0.3f' % (float(max(self._surfaces)-min(self._surfaces))/float(max(self._surfaces))))
        
        self.logger.debug('Sorting segments accoring to distance from center (default)')
        self.sortSegments()
        
              
    def getSurface(self):
        return self._surfaces
        
    def getHexagonCell(self):
        # need to draw two hexagons manually 
        # they will be used to generate the whole pattern
        cellSize = int(2./np.sqrt(3)*self._hexSize)
        cellSize += np.mod(cellSize,2)
        self._resCell = [cellSize]*2
        r = 1./np.sqrt(3)*self._hexSize
        angles = np.arange(-np.pi/2,-2.5*np.pi,-np.pi/3)
        self._firstHex = []
        # First one
        vertices = [ [cellSize//2+r*np.cos(a),cellSize//2+r*np.sin(a)] for a in angles]
#        self._firstHex.append(createPolygon(self._resCell,vertices))
        self._oneHex = np.argwhere(createPolygon(self._resCell,vertices)).astype(int)

        return self._oneHex
        # Second one
#        offsetX = (self._hexSize+self._gap)/2;
#        offsetX = offsetX-np.round(offsetX)
#        offsetY = (self._hexSize+self._gap)*np.sqrt(3)/2
#        offsetY = offsetY-np.round(offsetY)
#        vertices = [ [self._hexSize+1.+offsetX+r*np.cos(a),self._hexSize+1.+offsetY+r*np.sin(a)] for a in angles]
#        self._firstHex.append(createPolygon(self._resCell,vertices))
        
#        plt.figure(); plt.imshow(self._firstHex[0],interpolation = 'None')
#        plt.figure(); plt.imshow(self._firstHex[1],interpolation = 'None')
        
    def removeOneCol(self):
        '''
        Removes the center column of self.oneHex
        '''
        center = int(np.max(self._oneHex[:,1]) / 2)
        singleHex = [[duo[0],duo[1]-(np.sign(duo[1]-center)+1)/2] for duo in self._oneHex if duo[1] != center]
        self._oneHex = np.array(singleHex)
        
        
#    def getXOrder(self):
#        ''' 
#        Returns a dictionnary containing the indexes of elements
#        which share same X center value (= dict keys).
#        This is a preliminary function of self.evenize
#        '''
#        self.Xorder_dict = {}
#        for idx,value in enumerate(self._grid[:,1]):
#            if str(value) in layout_dict.keys():
#                self.Xorder_dict[str(value)] += [idx]
#            else:
#                self.Xorder_dict[str(value)] = [idx]
#
#    def evenize(self):
#        '''
#        For each hexagon, removes the centermost column so that the hexagon
#        becomes even, and also so they all have the same polarity.
#        '''
#        Xcenters = np.array(self.Xorder_dict.keys(),dtype = int)
#        Xcenters.sort()
#        num_keys = len(self.Xorder_dict.keys())
#        for x_col in Xcenters:
#            for idx in self.Xorder_dict[str(x_col)]:
#                new_part = [[duo[0],duo[1]-(np.sign(duo[1]-x_col)+1)/2] for duo in self._parts[idx] if duo[1] != x_col]
#                self._parts[idx] = new_part
#        
        
        
    def sortSegments(self,order='dist2center',rearrange = True):
        # sort the hexagons based on their distance to the center
        if order == 'dist2center':
            idx = np.array(self._rparts).argsort().astype(int)
        elif order == 'angles':
            idx = np.array(self._angles).argsort().astype(int)
        elif order == 'rnd':
            idx = range(self.nParts)
            shuffle(idx)
        else:
            self.logger.error('Invalid sorting order argument.')
            raise ValueError('Invalid sorting order argument.')
        if rearrange:
            self._parts = [self._parts[i] for i in idx]
            self._rparts = self._rparts[idx]
            self._grid = self._grid[idx]
            self._angles = self._angles[idx]
        return idx
    
        

    def getHexagonSegments(self):
        self.nParts = 0
        ny_max = int(np.floor(float(self._radius)/self._hexSize*2/np.sqrt(3)))
        rsq = []
        self._parts = []
        self._grid = []
        self._angles = []
        x_shift = int(np.floor(self._hexSize+self._gap))
        x_shift -= np.mod(x_shift+1,2) 
        y_shift = int(np.floor((self._gap+self._hexSize)*np.sqrt(3)/2))-1
        y_shift += np.mod(y_shift+1,2) 
        for y in np.arange(-ny_max-1,ny_max+1):
            ind = np.mod(y,2)
            # one out of two lines is shifted
            add_shift = ind*int(0.5*(self._hexSize+self._gap))
            if (float(self._radius)/y_shift)**2-y**2 > 0:
                nx_max = int(np.floor(np.sqrt((float(self._radius)/y_shift)**2-y**2)))
            else:
                nx_max = 2
            for x in np.arange(-nx_max-1,nx_max+1):
                # The -np.sign(x)*x was added to compensate the previously odd hexagon size
                # pos = [int(self._center[0]+x*x_shift+add_shift ),int(self._center[1]+y*y_shift - np.sign(x)*x)]
                pos = [int(self._center[0]+x*x_shift+add_shift ),int(self._center[1]+y*y_shift )]
                _rsq = (pos[0]-self._center[0])**2 +  (pos[1]-self._center[1])**2
                if (_rsq <= self._radius**2):
                    self._parts.append((self._oneHex+np.array(pos)-[self._resCell[0]/2,self._resCell[0]/2]).astype(int))
                    self._grid.append(pos)
                    self.nParts += 1
                    rsq.append(_rsq)
                    self._angles.append(np.arctan2(1.*(pos[0]-self._center[0]),1.*(pos[1]-self._center[1])))

        self._parts = self._parts
        self._grid = np.array(self._grid)
        self._angles = np.array(self._angles)
        self._rparts = np.sqrt(rsq)
        
     
  
    

    


class Diamonds(Layout):
    def __init__(self,radius,hexSize, resolution, center = None, gap = 0,verbose = True):
        
        Layout.__init__(self)  
        self._hexSize = hexSize
        self._radius = radius
        self._res = resolution
        self._surfaces = []
        self._grid = []
        self._gap = gap
        
        if center == None:
            self._center = [float(self._res[0]-1.)/2,float(self._res[1]-1.)/2]
        else:
            self._center = center
        
        if verbose:
            self.logger.info('Creation of hexagonal layout.')
#        print('Setting up the grid.')
#        self.setupGrid()
#        print('Creation of the hexagons.' )
        self._parts = []
        if verbose:
            self.logger.info('Creation of the hexagons.' )
        self.getHexagonCell()
        if verbose:
            self.logger.info('Setting up the grid.')
        self.getDiamondSegments()
        if verbose:
            self.logger.info(('-> Number of segments = %g' % self.nParts))
#        self.getFirstHexagons()
#        self.drawHexagons()
#        self.getHexagons()
#        self.checkOverlaps()
        # If no gap, we need to check that the segments do not overlap
        # We recompile the segments so that there is no overlap
        # Small disparities in the segment surfaces arise
        if self._gap == 0:
            if verbose:
                self.logger.info('Removing overlaps.')
            self.removeOverlaps()
            
        self.calculateSurfaces()
        if self._gap == 0:
            if verbose:
                self.logger.info(('-> Maximum relative variation of segment surfaces = %0.3f' % (float(max(self._surfaces)-min(self._surfaces))/float(max(self._surfaces)))))

        
        if verbose:
            self.logger.info('Sorting segments.')
        self.sortSegments()
        
              

        
    def getDiamondCell(self):
        # need to draw two diamond manually 
        # they will be used to generate the whole pattern
        cellSize = int(2./np.sqrt(3)*self._hexSize)
        cellSize += np.mod(cellSize,2)
        self._resCell = [cellSize]*2
        r = 1./np.sqrt(3)*self._hexSize
        angles = np.arange(-np.pi/2,-2.5*np.pi,-np.pi/2)
        self._firstHex = []
        # First one
        vertices = [ [cellSize//2+r*np.cos(a),cellSize//2+r*np.sin(a)] for a in angles]
#        self._firstHex.append(createPolygon(self._resCell,vertices))
        self._oneHex = np.argwhere(createPolygon(self._resCell,vertices)).astype(int)
        # Second one
#        offsetX = (self._hexSize+self._gap)/2;
#        offsetX = offsetX-np.round(offsetX)
#        offsetY = (self._hexSize+self._gap)*np.sqrt(3)/2
#        offsetY = offsetY-np.round(offsetY)
#        vertices = [ [self._hexSize+1.+offsetX+r*np.cos(a),self._hexSize+1.+offsetY+r*np.sin(a)] for a in angles]
#        self._firstHex.append(createPolygon(self._resCell,vertices))
        
#        plt.figure(); plt.imshow(self._firstHex[0],interpolation = 'None')
#        plt.figure(); plt.imshow(self._firstHex[1],interpolation = 'None')
        


        
    def sortSegments(self,order='dist2center',rearrange = True):
        # sort the diamond based on their distance to the center
        if order == 'dist2center':
            idx = np.array(self._rparts).argsort().astype(int)
        elif order == 'angles':
            idx = np.array(self._angles).argsort().astype(int)
        elif order == 'rndm':
            idx = range(self.nParts)
            shuffle(idx)    
        else:
            raise ValueError('Invalid sorting order argument.')
        if rearrange:
            self._parts = [self._parts[i] for i in idx]
            self._rparts = self._rparts[idx]
            self._grid = self._grid[idx]
            self._angles = self._angles[idx]
        return idx
    
        

    def getDiamondSegments(self):
        self.nParts = 0
        ny_max = int(np.floor(float(self._radius)/self._hexSize*2/np.sqrt(3)))
        rsq = []
        self._parts = []
        self._grid = []
        self._angles = []
#        x_shift = int(np.floor(self._hexSize+self._gap))-1
        x_shift = int((2*self._gap + self._hexSize))-2
#        x_shift -= np.mod(x_shift+1,2) 
#        y_shift = int(np.floor((self._gap+self._hexSize)*np.sqrt(3)/2))-1
        y_shift = int(np.floor(0.5*self._hexSize+self._gap))-1
        y_shift += np.mod(y_shift+1,2) 
        for y in np.arange(-ny_max-1,ny_max+1):
            ind = np.mod(y,2)
            # one out of two line is shifted
#            add_shift = ind*int(0.5*(self._hexSize+self._gap))
            add_shift = ind * 0.5 * (self._hexSize + 2*self._gap-2)#-ind*int(0.5*(np.sqrt(2)*self._gap + self._hexSize))
            if (float(self._radius)/y_shift)**2-y**2 > 0:
                nx_max = int(np.floor(np.sqrt((float(self._radius)/y_shift)**2-y**2)))
            else:
                nx_max = 2
#            print '<<', nx_max, ny_max, '>>'
            for x in np.arange(-nx_max-1,nx_max+1):
                pos = [int(self._center[0]+x*x_shift+add_shift),int(self._center[1]+y*y_shift)] # Warning, x and y and inverted, as they are in many parts of this code.
                _rsq = (pos[0]-self._center[0])**2 +  (pos[1]-self._center[1])**2
                if (_rsq <= self._radius**2):
                    self._parts.append((self._oneHex+np.array(pos)-[self._resCell[0]/2,self._resCell[0]/2]).astype(int))
                    self._grid.append(pos)
                    self.nParts += 1
                    rsq.append(_rsq)
                    self._angles.append(np.arctan2(1.*(pos[0]-self._center[0]),1.*(pos[1]-self._center[1])))

        self._parts = self._parts
        self._grid = np.array(self._grid)
        self._angles = np.array(self._angles)
        self._rparts = np.sqrt(rsq)
        
     
  
          
        

        
class Pie(Layout):
    def __init__(self,radius,nParts, resolution, center = None):
        
       
        Layout.__init__(self) 
        
        self._res = resolution        
        self.nParts = nParts
        

        if center == None:
            center = (self._res[0]//2,self._res[1]//2)
        
        X,Y = np.meshgrid(np.arange(self._res[1]),np.arange(self._res[0]))
        X = X-center[1]; Y = Y-center[0]

        R = np.sqrt(X**2+Y**2)
        Th = np.arctan2(X,Y)
        
        self._parts = []
        thetaBnd = np.linspace(-np.pi,np.pi,nParts+1)
        for i in range(nParts):
            self._parts.append( (R < radius)*(Th < thetaBnd[i+1])*(Th > thetaBnd[i]))
